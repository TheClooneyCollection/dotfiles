#!/usr/bin/env python3
"""Offline integration tests, using isolated roots and fixture upstreams."""
import argparse
import contextlib
import importlib.machinery
import importlib.util
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

loader = importlib.machinery.SourceFileLoader('manager', str(Path(__file__).resolve().parents[1] / 'skill-manager'))
spec = importlib.util.spec_from_loader(loader.name, loader)
mod = importlib.util.module_from_spec(spec); loader.exec_module(mod)
A = 'skills/productivity/a'
B = 'library/b'


class Tests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(); self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.config = {
            'agents': {'claude': '.claude/skills', 'codex': '.codex/skills', 'codex-2nd': '.codex-2nd/skills'},
            'default_agents': ['claude', 'codex', 'codex-2nd'],
            'sources': {
                'one': {'kind': 'github', 'repository': 'owner/one', 'directory': '.agents/skills/one', 'skill_roots': ['skills'], 'required_files': ['LICENSE'], 'parent_readme': True},
                'two': {'kind': 'github', 'repository': 'owner/two', 'directory': '.agents/skills/two', 'skill_roots': ['library'], 'required_files': ['COPYING']},
                'local': {'kind': 'local', 'directory': '.agents/skills/local', 'skill_roots': ['.']}}}
        (self.root / mod.CONFIG).parent.mkdir(parents=True)
        (self.root / mod.CONFIG).write_bytes(mod.encoded(self.config))
        self.remote = {
            'owner/one': {'LICENSE': (b'MIT\n', False), A + '/SKILL.md': (b'A\n', False), A + '/run.sh': (b'#!/bin/sh\n', True)},
            'owner/two': {'COPYING': (b'License\n', False), B + '/SKILL.md': (b'B\n', False)}}
        real_snapshot = mod.snapshot
        def fake(root, source, ref):
            if source['kind'] == 'local':
                return real_snapshot(root, source, ref)
            return ref or 'commit1', self.remote[source['repository']].copy()
        p = patch.object(mod, 'snapshot', side_effect=fake); p.start(); self.addCleanup(p.stop)

    def run_action(self, action, paths=(), source='one', agents=None, category=None):
        args = argparse.Namespace(action=action, skills=list(paths), source=source, agents=agents, category=category, ref=None)
        with contextlib.redirect_stdout(io.StringIO()) as output:
            result = mod.Manager(self.root).run(args)
        return result, output.getvalue()

    def files(self):
        return {str(p.relative_to(self.root)): ('link', str(p.readlink())) if p.is_symlink()
                else ('file', p.read_bytes(), p.stat().st_mode & 0o777) for p in self.root.rglob('*') if p.is_file() or p.is_symlink()}

    def target(self, source='one', path=A):
        return self.root / self.config['sources'][source]['directory'] / path

    def test_default_three_and_explicit_one_preserved_on_update(self):
        self.run_action('import', [A])
        for client in self.config['agents'].values():
            self.assertTrue((self.root / client / 'a').is_symlink())
        self.run_action('import', [B], 'two', agents='claude')
        self.remote['owner/two'][B + '/SKILL.md'] = (b'New\n', False)
        self.run_action('update', source='two')
        for client in ['codex', 'codex-2nd']:
            self.assertFalse((self.root / self.config['agents'][client] / 'b').exists())
        self.assertEqual(mod.Manager(self.root).lock['sources']['two']['skills'][B]['agents'], ['claude'])

    def test_explicit_install_and_uninstall_persist(self):
        self.run_action('import', [A])
        self.run_action('uninstall', [A], agents='codex')
        self.run_action('update')
        self.assertFalse(os.path.lexists(self.root / '.codex/skills/a'))
        self.assertTrue(self.target().exists())
        self.run_action('install', [A], agents='codex')
        self.assertTrue((self.root / '.codex/skills/a').is_symlink())
        self.run_action('uninstall', [A])
        self.run_action('update')
        self.assertEqual(mod.Manager(self.root).lock['sources']['one']['skills'][A]['agents'], [])

    def test_readonly_commands_and_offline_inventory(self):
        self.run_action('import', [A]); before = self.files()
        self.assertEqual(self.run_action('check')[0], 0)
        self.remote['owner/one'][A + '/SKILL.md'] = (b'New\n', False)
        status, output = self.run_action('diff')
        self.assertEqual(status, 1); self.assertIn('+New', output)
        self.run_action('list')
        with patch.object(mod, 'snapshot', side_effect=AssertionError('must be offline')):
            self.run_action('installed', source=None, agents='claude')
            self.run_action('sources', source=None)
        self.assertEqual(self.files(), before)

    def test_cross_source_collision(self):
        self.run_action('import', [A])
        self.remote['owner/two']['library/a/SKILL.md'] = (b'Other\n', False)
        before = self.files()
        with self.assertRaisesRegex(ValueError, 'collision'):
            self.run_action('import', ['library/a'], 'two')
        self.assertEqual(self.files(), before)

    def test_local_edits_and_removed_upstream_block_writes(self):
        self.run_action('import', [A]); (self.target() / 'mine').write_text('keep')
        before = self.files()
        with self.assertRaisesRegex(ValueError, 'local changes'):
            self.run_action('update')
        self.assertEqual(self.files(), before)
        (self.target() / 'mine').unlink()
        del self.remote['owner/one'][A + '/SKILL.md']; before = self.files()
        with self.assertRaisesRegex(ValueError, 'removed upstream'):
            self.run_action('update')
        self.assertEqual(self.files(), before)

    def test_executable_bits_and_deleted_support_files(self):
        self.run_action('import', [A]); script = self.target() / 'run.sh'
        self.assertTrue(script.stat().st_mode & 0o111)
        script.chmod(0o644)
        self.assertEqual(self.run_action('check')[0], 1)
        with self.assertRaisesRegex(ValueError, 'local changes'):
            self.run_action('update')
        script.chmod(0o755)
        del self.remote['owner/one'][A + '/run.sh']
        self.run_action('update'); self.assertFalse(script.exists())

    def test_local_source_registration_edit_and_cleanup(self):
        local = self.target('local', 'mine'); local.mkdir(parents=True)
        (local / 'SKILL.md').write_text('local')
        self.run_action('import', ['mine'], 'local')
        (local / 'SKILL.md').write_text('edited locally')
        self.assertEqual(self.run_action('check', source='local')[0], 0)
        self.run_action('uninstall', ['mine'], 'local', agents='claude')
        self.assertEqual((local / 'SKILL.md').read_text(), 'edited locally')
        self.run_action('update', source='local')
        self.assertFalse(os.path.lexists(self.root / '.claude/skills/mine'))

    def test_refuse_replaced_link_on_cleanup(self):
        self.run_action('import', [A]); link = self.root / '.claude/skills/a'
        link.unlink(); link.mkdir(); (link / 'mine').write_text('keep')
        before = self.files()
        with self.assertRaisesRegex(ValueError, 'collision'):
            self.run_action('uninstall', [A], agents='claude')
        self.assertEqual(self.files(), before)

    def test_rollback_on_mid_update_failure(self):
        self.run_action('import', [A]); before = self.files()
        self.remote['owner/one'][A + '/SKILL.md'] = (b'New\n', False)
        real = os.replace
        failed = False
        def fail_once(src, dest):
            nonlocal failed
            if Path(dest) == self.root / mod.LOCK and Path(src).name.startswith('new-') and not failed:
                failed = True
                raise OSError('simulated disk failure')
            return real(src, dest)
        with patch.object(mod.os, 'replace', side_effect=fail_once):
            with self.assertRaisesRegex(OSError, 'simulated'):
                self.run_action('update')
        self.assertTrue(failed)
        self.assertEqual(self.files(), before)

    def test_bad_agent_and_path_are_rejected(self):
        for agents in ['unknown', 'claude,unknown']:
            with self.assertRaisesRegex(ValueError, 'unknown agent'):
                self.run_action('import', [A], agents=agents)
        with self.assertRaisesRegex(ValueError, 'relative path'):
            self.run_action('import', ['../escape'])

    def test_nondefault_layout_license_and_category(self):
        self.run_action('import', source='one', category='productivity')
        self.run_action('import', [B], 'two')
        self.assertTrue((self.root / '.agents/skills/two/COPYING').exists())
        self.assertEqual(self.run_action('check', source=None)[0], 0)

    def test_updates_cannot_change_agent_selection(self):
        self.run_action('import', [A], agents='claude')
        before = self.files()
        with self.assertRaisesRegex(ValueError, 'preserves recorded choices'):
            self.run_action('update', agents='codex')
        self.assertEqual(self.files(), before)

    def test_overlapping_targets_and_source_symlink_rejected(self):
        with self.assertRaisesRegex(ValueError, 'overlapping mutation'):
            mod.transact(self.root, [(self.root / 'x', 'tree', {}),
                                     (self.root / 'x/child', 'file', b'data')])
        source = self.root / '.agents/skills/one'
        source.parent.mkdir(parents=True)
        elsewhere = self.root / 'elsewhere'; elsewhere.mkdir()
        source.symlink_to(elsewhere)
        with self.assertRaisesRegex(ValueError, 'source directory is a symlink'):
            mod.Manager(self.root)

    def test_link_repair_manifest_drift_and_metadata_protection(self):
        self.run_action('import', [A]); link = self.root / '.codex/skills/a'; link.unlink()
        self.assertEqual(self.run_action('check')[0], 1)
        self.run_action('install', [A], agents='codex'); self.assertTrue(link.is_symlink())
        (self.root / mod.INVENTORY).write_text('{}')
        self.assertEqual(self.run_action('check')[0], 1)
        self.run_action('update'); self.assertEqual(self.run_action('check')[0], 0)
        (self.root / '.agents/skills/one/LICENSE').write_text('local license')
        before = self.files()
        with self.assertRaisesRegex(ValueError, 'metadata'):
            self.run_action('update')
        self.assertEqual(self.files(), before)


if __name__ == '__main__':
    unittest.main()
