"""Build the changelog from first-parent conventional feat/fix commits and Markdown notes.

Settings live in tools/build_changelog.json; without it the defaults below apply.
No commit hash is embedded, so refreshing and amending the current commit is stable.
"""
import argparse
import json
import re
import subprocess
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT/'tools/build_changelog.json'
PATTERN = re.compile(r'^(feat|fix)(?:\([^)]*\))?(!?):\s+(.+)$')
SCHEMES = ('beta', 'semver', 'calver')
DEFAULTS = dict(scheme='beta', notes_dir='docs/development/changelog-notes', legacy_minor_entries=0,
                outputs=dict(markdown='CHANGELOG.md'))
OUTPUTS = ('json', 'markdown', 'version_file')


# beta:   v0.MINOR.PATCH. feat bumps MINOR and resets PATCH, fix bumps PATCH. The first
#         `legacy` entries predate patch releases and each bump MINOR.
# semver: vMAJOR.MINOR.PATCH. Like beta, and a `!` subject (feat!: ...) bumps MAJOR.
# calver: releases are dated tags chosen by hand, so entries carry only their date.
def build(records, notes, scheme='beta', legacy=0):
    entries = []
    major = minor = patch = 0
    for subject, date in records:
        match = PATTERN.match(subject)
        if not match:
            continue
        kind, breaking, fallback = match.groups()
        if scheme == 'semver' and breaking:
            major, minor, patch = major+1, 0, 0
        elif kind == 'feat' or (scheme == 'beta' and len(entries) < legacy):
            minor, patch = minor+1, 0
        else:
            patch += 1
        note = notes.get(subject, {})
        entry = {} if scheme == 'calver' else dict(version=f'v{major}.{minor}.{patch}')
        entry.update(date=date, kind=kind, title=note.get('title', fallback), details=note.get('details', []))
        entries.append(entry)
    return dict(version=None if scheme == 'calver' else f'v{major}.{minor}.{patch}', count=len(entries),
                feature_count=sum(e['kind']=='feat' for e in entries),
                fix_count=sum(e['kind']=='fix' for e in entries), entries=list(reversed(entries)))


# Deliberately small frontmatter subset: exactly two JSON-quoted string values.
# JSON escaping preserves Unicode, quotes and newlines without a YAML dependency.
NOTE_FILENAME = re.compile(r"^(\d{8}T\d{6}Z)-[a-z0-9]+(?:-[a-z0-9]+)*\.md$")


def read_notes(directory):
    notes = {}
    if not directory.exists():
        return notes
    for path in sorted(directory.glob('*.md')):
        if path.name == 'README.md':
            continue
        try:
            match = NOTE_FILENAME.fullmatch(path.name)
            if not match:
                raise ValueError('expected <YYYYMMDDTHHMMSSZ>-<slug>.md')
            datetime.strptime(match.group(1), '%Y%m%dT%H%M%SZ')
            lines = path.read_text(encoding='utf-8').split('\n')
            if lines[0] != '---':
                raise ValueError('missing opening frontmatter delimiter')
            end = lines.index('---', 1)
            metadata = {}
            for line in lines[1:end]:
                key, separator, value = line.partition(': ')
                if not separator or key not in ('subject', 'title') or key in metadata:
                    raise ValueError('frontmatter requires unique subject and title fields')
                metadata[key] = json.loads(value)
                if not isinstance(metadata[key], str) or not metadata[key]:
                    raise ValueError('frontmatter values must be nonempty JSON strings')
            if set(metadata) != {'subject', 'title'}:
                raise ValueError('frontmatter requires subject and title')
            details = []
            body = lines[end+1:]
            while body and body[0] == '': body.pop(0)
            if body and body[-1] == '': body.pop()
            for line in body:
                if line.startswith('- '):
                    details.append(line[2:])
                elif line.startswith('  ') and details:
                    details[-1] += '\n' + line[2:]
                else:
                    raise ValueError('body requires - list items and two-space continuations')
            subject = metadata['subject']
            if subject in notes:
                raise ValueError('duplicate subject: ' + subject)
            notes[subject] = dict(title=metadata['title'], details=details)
        except (ValueError, IndexError) as error:
            raise ValueError(f'{path}: {error}') from error
    return notes


def render_markdown(data):
    lines = ['# Changelog', '']
    if not data['entries']:
        lines += ['No feature or fix commits yet.']
    for entry in data['entries']:
        meta = [f"`{entry['version']}`"] if 'version' in entry else []
        meta += [entry['date'], 'Feature' if entry['kind'] == 'feat' else 'Fix']
        lines += ['## '+entry['title'].replace('\n', ' '), '', ' · '.join(meta), '']
        lines += ['- '+detail.replace('\n', '\n  ') for detail in entry['details']]
        if entry['details']:
            lines.append('')
    return '\n'.join(line.rstrip() for line in '\n'.join(lines).split('\n')).rstrip('\n')+'\n'


# version_file: {"path": ..., "line": "version = \"{version}\"", "after": optional anchor}.
# Replaces the line that starts like `line`, or inserts it after `after`, or appends it.
# A `line` of just "{version}" makes the whole file the version (a VERSION file).
def update_version_line(current, spec, version):
    line = spec['line'].format(version=version)
    if spec['line'].startswith('{version}'):
        return line+'\n'
    prefix = re.compile('^'+re.escape(spec['line'].split('{version}')[0])+'.*$', re.M)
    if prefix.search(current):
        return prefix.sub(lambda _: line, current)
    anchor = spec.get('after')
    if anchor and anchor in current:
        return current.replace(anchor, anchor+'\n\n'+line, 1)
    return (current.rstrip('\n')+'\n' if current else '')+line+'\n'


def load_config():
    config = json.loads(CONFIG.read_text(encoding='utf-8')) if CONFIG.exists() else {}
    unknown = set(config)-set(DEFAULTS) | set(config.get('outputs', {}))-set(OUTPUTS)
    if unknown:
        raise SystemExit(f'{CONFIG.name}: unknown settings: '+', '.join(sorted(unknown)))
    settings = {**DEFAULTS, **config}
    if settings['scheme'] not in SCHEMES:
        raise SystemExit(f'{CONFIG.name}: scheme must be one of '+', '.join(SCHEMES))
    return settings


def outputs():
    settings = load_config()
    has_commits = subprocess.run(['git','rev-parse','--verify','-q','HEAD'], cwd=ROOT, capture_output=True).returncode == 0
    log = subprocess.check_output(['git','log','--first-parent','--reverse','--date=short','--format=%s%x1f%ad'], cwd=ROOT, text=True) if has_commits else ''
    records = [line.rsplit('\x1f',1) for line in log.splitlines() if '\x1f' in line]
    data = build(records, read_notes(ROOT/settings['notes_dir']), settings['scheme'], settings['legacy_minor_entries'])
    targets = settings['outputs']
    result = {}
    if targets.get('json'):
        result[ROOT/targets['json']] = json.dumps(data,ensure_ascii=False,indent=2)+'\n'
    if targets.get('markdown'):
        result[ROOT/targets['markdown']] = render_markdown(data)
    spec = targets.get('version_file')
    if spec and data['version']:
        path = ROOT/spec['path']
        result[path] = update_version_line(path.read_text(encoding='utf-8') if path.exists() else '', spec, data['version'])
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true',help='fail if a generated file is stale')
    parser.add_argument('--outputs',action='store_true',help='print the generated paths, one per line')
    args = parser.parse_args()
    if args.outputs:
        for path in outputs():print(path.relative_to(ROOT))
        return
    stale = []
    for path, content in outputs().items():
        if args.check:
            if not path.exists() or path.read_text(encoding='utf-8')!=content:stale.append(str(path.relative_to(ROOT)))
        else:
            path.parent.mkdir(parents=True,exist_ok=True)
            path.write_text(content,encoding='utf-8')
    if stale:raise SystemExit('Changelog needs refresh: '+', '.join(stale))

if __name__=='__main__':main()
