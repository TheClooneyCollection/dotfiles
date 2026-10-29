import json
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path
from build_changelog import build, read_notes, render_markdown, update_version_line

SOURCE = Path(__file__).resolve().parents[1]
GODOT = dict(json='client/data/changelog.json',
             version_file=dict(path='client/project.godot', line='config/version="{version}"', after='[application]'))


def fixture_repo(root, config=None):
    """A Git repo with the changelog tools copied in; config None means no config file (defaults)."""
    def git(*args):return subprocess.check_output(['git',*args],cwd=root,text=True,stderr=subprocess.STDOUT).strip()
    git('init','-q','-b','main');git('config','user.name','Test');git('config','user.email','test@example.invalid')
    for folder in ['tools','scripts','docs/development/changelog-notes']:(root/folder).mkdir(parents=True,exist_ok=True)
    shutil.copyfile(SOURCE/'tools/build_changelog.py',root/'tools/build_changelog.py')
    shutil.copyfile(SOURCE/'scripts/refresh-changelog.sh',root/'scripts/refresh-changelog.sh')
    if config is not None:(root/'tools/build_changelog.json').write_text(json.dumps(config))
    return git


class ChangelogTest(unittest.TestCase):
    def test_only_feature_and_fix_commits_advance_version(self):
        result=build([('docs: design','2026-01-01'),('feat(client): Village','2026-01-02'),('fix: Sound','2026-01-03'),('chore: refresh log','2026-01-04'),('feat!: Pets','2026-01-05')],{},legacy=99)
        self.assertEqual(result['version'],'v0.3.0')
        self.assertEqual([e['version'] for e in result['entries']],['v0.3.0','v0.2.0','v0.1.0'])
        self.assertEqual((result['feature_count'],result['fix_count']),(2,1))
    def test_curated_player_notes_and_readable_fallback(self):
        result=build([('feat: Pets','today'),('fix(ui): Close button','today')],{'feat: Pets':{'title':'宠物加入','details':['可以骑金虎。']}})
        self.assertEqual(result['entries'][0]['title'],'Close button')
        self.assertEqual(result['entries'][1]['title'],'宠物加入')
        self.assertNotIn('hash',result['entries'][1])
    def test_after_legacy_feat_bumps_minor_and_fix_bumps_patch(self):
        records=[('feat: A','d'),('fix: B','d'),('fix: C','d'),('feat: D','d'),('docs: E','d'),('fix: F','d')]
        result=build(records,{},legacy=1)
        self.assertEqual([e['version'] for e in reversed(result['entries'])],['v0.1.0','v0.1.1','v0.1.2','v0.2.0','v0.2.1'])
        self.assertEqual(result['version'],'v0.2.1')
    def test_legacy_fixes_keep_minor_numbers(self):
        result=build([('feat: A','d'),('fix: B','d'),('fix: C','d')],{},legacy=2)
        self.assertEqual([e['version'] for e in reversed(result['entries'])],['v0.1.0','v0.2.0','v0.2.1'])
    def test_empty_history(self):
        self.assertEqual(build([],{})['version'],'v0.0.0')
    def test_semver_breaking_subject_bumps_major(self):
        records=[('feat: A','d'),('fix: B','d'),('feat(api)!: C','d'),('fix!: D','d'),('feat: E','d')]
        result=build(records,{},scheme='semver',legacy=5)
        self.assertEqual([e['version'] for e in reversed(result['entries'])],['v0.1.0','v0.1.1','v1.0.0','v2.0.0','v2.1.0'])
    def test_calver_entries_carry_only_dates(self):
        result=build([('feat: A','2026-10-01'),('fix: B','2026-10-02')],{},scheme='calver')
        self.assertIsNone(result['version'])
        self.assertEqual(result['entries'][0],dict(date='2026-10-02',kind='fix',title='B',details=[]))
    def test_markdown_lists_newest_first_with_details(self):
        result=build([('feat: A','2026-10-01'),('fix: B','2026-10-02')],{'feat: A':{'title':'Two\nlines','details':['first\nsecond\n\nthird']}})
        self.assertEqual(render_markdown(result),'# Changelog\n\n## B\n\n`v0.1.1` · 2026-10-02 · Fix\n\n## Two lines\n\n`v0.1.0` · 2026-10-01 · Feature\n\n- first\n  second\n\n  third\n')
        self.assertEqual(render_markdown(build([('fix: B','2026-10-02')],{},scheme='calver')),'# Changelog\n\n## B\n\n2026-10-02 · Fix\n')
        self.assertIn('No feature or fix commits yet.',render_markdown(build([],{})))
    def test_version_line_replaced_inserted_or_appended(self):
        spec=dict(line='version = "{version}"',after='[package]')
        self.assertEqual(update_version_line('[package]\nversion = "v0.1.0"\n',spec,'v0.2.0'),'[package]\nversion = "v0.2.0"\n')
        self.assertEqual(update_version_line('[package]\nname = "x"\n',spec,'v0.2.0'),'[package]\n\nversion = "v0.2.0"\nname = "x"\n')
        self.assertEqual(update_version_line('',dict(line='{version}'),'v1.0.0'),'v1.0.0\n')
        self.assertEqual(update_version_line('name\n',dict(line='{version}'),'v1.0.0'),'v1.0.0\n')


class ConfigTest(unittest.TestCase):
    def run_build(self, config, *args):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);git=fixture_repo(root,config)
            git('add','.');git('commit','-qm','feat: First slice')
            run=subprocess.run(['python3','tools/build_changelog.py',*args],cwd=root,capture_output=True,text=True)
            files={str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.parts}
            return run,files
    def test_defaults_write_markdown_only(self):
        run,files=self.run_build(None)
        self.assertEqual(run.returncode,0,run.stderr)
        self.assertIn('CHANGELOG.md',files);self.assertNotIn('client/data/changelog.json',files)
        self.assertEqual(self.run_build(None,'--outputs')[0].stdout,'CHANGELOG.md\n')
    def test_repo_without_commits_builds_an_empty_changelog(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);fixture_repo(root)
            subprocess.run(['python3','tools/build_changelog.py'],cwd=root,check=True)
            self.assertIn('No feature or fix commits yet.',(root/'CHANGELOG.md').read_text())
    def test_unknown_settings_and_schemes_are_rejected(self):
        for config,message in [({'sheme':'beta'},'unknown settings: sheme'),({'outputs':{'html':'x'}},'unknown settings: html'),({'scheme':'date'},'scheme must be one of')]:
            run,_=self.run_build(config)
            self.assertNotEqual(run.returncode,0);self.assertIn(message,run.stderr)
    def test_readme_in_notes_folder_is_not_a_note(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);(root/'README.md').write_text('# Changelog notes\n')
            self.assertEqual(read_notes(root),{})


class RefreshWorkflowTest(unittest.TestCase):
    def test_refresh_amend_stable_and_preserves_unrelated_index(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);git=fixture_repo(root,dict(outputs=GODOT))
            (root/'client/data').mkdir(parents=True)
            (root/'client/project.godot').write_text('[application]\nconfig/name="Fixture"\n')
            (root/'client/data/changelog.json').write_text('{}\n')
            git('add','.');git('commit','-qm','feat: First playable slice')
            (root/'unrelated.txt').write_text('keep staged\n');git('add','unrelated.txt')
            subprocess.run(['sh','scripts/refresh-changelog.sh'],cwd=root,check=True,stdout=subprocess.DEVNULL)
            self.assertEqual(git('diff','--cached','--name-only'),'unrelated.txt')
            data=json.loads((root/'client/data/changelog.json').read_text())
            self.assertEqual(data['version'],'v0.1.0')
            self.assertIn('config/version="v0.1.0"',(root/'client/project.godot').read_text())
            before=git('rev-parse','HEAD')
            subprocess.run(['sh','scripts/refresh-changelog.sh'],cwd=root,check=True,stdout=subprocess.DEVNULL)
            self.assertEqual(git('rev-parse','HEAD'),before)
            (root/'client/project.godot').write_text('[application]\nconfig/name="Unsaved user edit"\n')
            blocked=subprocess.run(['sh','scripts/refresh-changelog.sh'],cwd=root,capture_output=True)
            self.assertNotEqual(blocked.returncode,0)
            self.assertIn('Unsaved user edit',(root/'client/project.godot').read_text())
    def test_refresh_adds_a_new_markdown_changelog_to_the_commit(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);git=fixture_repo(root)
            git('add','.');git('commit','-qm','chore: initial project skeleton')
            (root/'a.txt').write_text('a');git('add','a.txt');git('commit','-qm','feat: First feature')
            subprocess.run(['sh','scripts/refresh-changelog.sh'],cwd=root,check=True,stdout=subprocess.DEVNULL)
            self.assertEqual(git('status','--porcelain'),'')
            self.assertEqual(sorted(git('show','--name-only','--format=','HEAD').split('\n')),['CHANGELOG.md','a.txt'])
            self.assertIn('## First feature',(root/'CHANGELOG.md').read_text())
            (root/'CHANGELOG.md').write_text('hand edit\n')
            blocked=subprocess.run(['sh','scripts/refresh-changelog.sh'],cwd=root,capture_output=True)
            self.assertNotEqual(blocked.returncode,0)
            self.assertEqual((root/'CHANGELOG.md').read_text(),'hand edit\n')


class MarkdownNotesTest(unittest.TestCase):
    def test_roundtrip_and_invalid_notes(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory)
            path=root/'20261001T120000Z-unicode.md'
            valid='---\nsubject: '+json.dumps('fix: "引号"',ensure_ascii=False)+'\ntitle: '+json.dumps('多行\n标题',ensure_ascii=False)+'\n---\n\n- 第一行\n  第二行\n  \n  - 嵌套文字\n- 顺序二\n'
            path.write_text(valid)
            self.assertEqual(read_notes(root)['fix: "引号"'],dict(title='多行\n标题',details=['第一行\n第二行\n\n- 嵌套文字','顺序二']))
            other=root/'20261001T120001Z-duplicate.md';other.write_text(valid)
            with self.assertRaisesRegex(ValueError,'duplicate subject'):read_notes(root)
            other.unlink()
            for bad in [valid.replace('subject: ', 'unknown: '),valid.replace('title: ', 'subject: '),valid.replace('---\n','',1),valid.replace('- 第一行','unsupported'),valid.replace('title: "多行\\n标题"','title: 3')]:
                path.write_text(bad)
                with self.assertRaises(ValueError):read_notes(root)
            path.write_text(valid)
            for name in ['bad.md','20260230T120000Z-invalid.md','20261001T250000Z-invalid.md']:
                path.rename(root/name)
                with self.assertRaises(ValueError):read_notes(root)
                (root/name).rename(path)

    def test_real_git_first_parent_cherry_pick_and_rebase(self):
        with tempfile.TemporaryDirectory() as directory:
            root=Path(directory);git=fixture_repo(root,dict(outputs=GODOT))
            def commit(subject,file):
                (root/file).write_text(subject);git('add','.');git('commit','-qm',subject)
            def generate():
                subprocess.run(['python3','tools/build_changelog.py'],cwd=root,check=True)
                return json.loads((root/'client/data/changelog.json').read_text())
            (root/'client').mkdir()
            (root/'client/project.godot').write_text('[application]\n')
            # Filename dates intentionally oppose the Git ordering.
            for stamp,subject,title in [('20261001T120000Z','fix: Side','侧线'),('20261002T120000Z','feat: Main','主线')]:
                (root/f'docs/development/changelog-notes/{stamp}-note.md').write_text('---\nsubject: '+json.dumps(subject)+'\ntitle: '+json.dumps(title)+'\n---\n\n- 说明\n')
            commit('chore: setup','setup')
            git('checkout','-qb','side');commit('fix: Side','side');side=git('rev-parse','HEAD')
            git('checkout','-q','main');commit('feat: Main','main')
            git('merge','--no-ff','-qm','chore: merge side','side')
            self.assertEqual([e['title'] for e in generate()['entries']],['主线'])
            git('reset','--hard','HEAD^');git('cherry-pick',side)
            self.assertEqual([e['title'] for e in generate()['entries']],['侧线','主线'])
            git('restore','client/project.godot');(root/'client/data/changelog.json').unlink()
            git('checkout','-q','side');commit('fix: Rebased follow-up','follow-up');git('rebase','main')
            self.assertEqual([e['title'] for e in generate()['entries']],['Rebased follow-up','侧线','主线'])
            commit('fix: No curated note','no-note')
            self.assertEqual(generate()['entries'][0]['title'],'No curated note')

if __name__=='__main__':unittest.main()
