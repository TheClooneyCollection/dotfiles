#!/usr/bin/env python3
"""Offline behavior tests; all writes are confined to temporary directories."""
import argparse
import contextlib
import importlib.machinery
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / 'mattpocock-skills'
loader = importlib.machinery.SourceFileLoader('vendor', str(SCRIPT))
spec = importlib.util.spec_from_loader(loader.name, loader)
mod = importlib.util.module_from_spec(spec)
loader.exec_module(mod)
A = 'skills/productivity/a'
B = 'skills/engineering/b'


class VendorTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.dest = self.root / '.agents/skills/mattpocock'
        self.remote = {
            'LICENSE': b'MIT\n', 'skills/productivity/README.md': b'Productivity\n',
            A + '/SKILL.md': b'---\nname: a\ndescription: test\n---\nOld\n',
            A + '/agents/openai.yaml': b'policy:\n  allow_implicit_invocation: false\n',
            B + '/SKILL.md': b'---\nname: b\ndescription: test\n---\nOther\n'}
        for key, value in [('ROOT', self.root), ('DEST', self.dest)]:
            p = patch.object(mod, key, value); p.start(); self.addCleanup(p.stop)
        p = patch.object(mod, 'snapshot', side_effect=lambda ref: ('abc123', self.remote.copy()))
        p.start(); self.addCleanup(p.stop)

    def run_action(self, action, skills=None, category=None):
        with contextlib.redirect_stdout(io.StringIO()) as output:
            status = mod.run(argparse.Namespace(action=action, skills=skills or [], category=category, ref='main'))
        return status, output.getvalue()

    def tree(self):
        return {str(p.relative_to(self.root)): ('link', str(p.readlink())) if p.is_symlink()
                else ('file', p.read_bytes()) for p in self.root.rglob('*') if p.is_symlink() or p.is_file()}

    def install(self):
        self.run_action('import', category='productivity')

    def test_import_preserves_files_and_three_links(self):
        self.install()
        for file, data in mod.subset(self.remote, A).items():
            self.assertEqual((self.dest / A / file).read_bytes(), data)
        for link in mod.links(A):
            self.assertTrue(link.is_symlink())
            self.assertEqual(link.resolve(), self.dest / A)
        self.assertEqual(json.loads((self.dest / 'upstream.json').read_text())['skills'][A]['commit'], 'abc123')

    def test_check_diff_list_are_read_only(self):
        self.install(); before = self.tree()
        self.assertEqual(self.run_action('check')[0], 0)
        self.remote[A + '/SKILL.md'] += b'New\n'
        self.assertEqual(self.run_action('check')[0], 1)
        status, diff = self.run_action('diff')
        self.assertEqual(status, 1); self.assertIn('+New', diff)
        self.run_action('list')
        self.assertEqual(self.tree(), before)

    def test_update_replaces_removed_support_file_and_repairs_link(self):
        self.install()
        next(mod.links(A)).unlink()
        self.assertEqual(self.run_action('check')[0], 1)
        del self.remote[A + '/agents/openai.yaml']
        self.remote[A + '/SKILL.md'] += b'New\n'
        self.run_action('update')
        self.assertFalse((self.dest / A / 'agents/openai.yaml').exists())
        self.assertTrue(next(mod.links(A)).is_symlink())
        self.assertEqual(self.run_action('check')[0], 0)

    def test_local_changes_block_all_writes(self):
        self.install(); (self.dest / A / 'local.txt').write_text('keep')
        self.remote[A + '/SKILL.md'] += b'New\n'; before = self.tree()
        with self.assertRaisesRegex(ValueError, 'local changes'):
            self.run_action('update')
        self.assertEqual(self.tree(), before)

    def test_link_collision_blocks_import_without_partial_writes(self):
        target = next(mod.links(A)); target.mkdir(parents=True)
        (target / 'mine').write_text('keep'); before = self.tree()
        with self.assertRaisesRegex(ValueError, 'collision'):
            self.run_action('import', category='productivity')
        self.assertEqual(self.tree(), before)

    def test_selective_import_and_removed_upstream(self):
        self.install(); self.run_action('import', [B])
        self.assertEqual(len(json.loads((self.dest / 'upstream.json').read_text())['skills']), 2)
        del self.remote[B + '/SKILL.md']; before = self.tree()
        with self.assertRaisesRegex(ValueError, 'removed upstream'):
            self.run_action('update')
        self.assertEqual(self.tree(), before)

    def test_metadata_local_changes_block_update(self):
        self.install(); (self.dest / 'LICENSE').write_text('local edit')
        before = self.tree()
        self.assertEqual(self.run_action('check')[0], 1)
        with self.assertRaisesRegex(ValueError, 'metadata changes'):
            self.run_action('update')
        self.assertEqual(self.tree(), before)

    def test_unknown_and_duplicate_names_block_import(self):
        with self.assertRaisesRegex(ValueError, 'unknown skill'):
            self.run_action('import', ['../../outside'])
        self.install()
        self.remote['skills/engineering/a/SKILL.md'] = b'duplicate'
        before = self.tree()
        with self.assertRaisesRegex(ValueError, 'duplicate skill name'):
            self.run_action('import', ['skills/engineering/a'])
        self.assertEqual(self.tree(), before)


if __name__ == '__main__':
    unittest.main()
