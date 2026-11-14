#!/usr/bin/env python3
"""Exercise installed-command delegation and legacy startup on a private socket."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import uuid

ROOT = Path(__file__).resolve().parents[2]


class LauncherDelegation(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='tmux-launcher-test-')
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.socket = 'launcher-test-' + uuid.uuid4().hex
        self.env = dict(os.environ)
        for key in ('TMUX', 'TMUX_PANE', 'FROM_PANE', 'TMUX_MAIN_SEQUENCE_AGENT'):
            self.env.pop(key, None)
        self.env.update(PATH=str(self.directory) + os.pathsep + os.environ['PATH'],
                        TMUX_MAIN_SEQUENCE_SOCKET=self.socket,
                        TMUX_MAIN_SEQUENCE_SESSION='legacy-test',
                        TEST_SUPPORTED='0',
                        TEST_CALL_LOG=str(self.directory / 'calls'),
                        TMUX_MAIN_SEQUENCE_CONFIG=str(self.directory / 'projects'))
        stub = self.directory / 'tmux-agents'
        stub.write_text('''#!/usr/bin/env python3
import json, os, sys
with open(os.environ['TEST_CALL_LOG'], 'a') as log:
    log.write(repr(sys.argv))
print(json.dumps(sys.argv[1:]))
# v1.19.0 falls through to the browser and succeeds for unknown commands.
sys.exit(7 if os.environ.get('TEST_SUPPORTED') == '1' else 0)
''')
        stub.chmod(0o755)

    def run_launcher(self, name, *args):
        return subprocess.run([str(ROOT / '.bin' / name), *args], env=self.env,
                              text=True, capture_output=True)

    def tmux(self, *args, check=True):
        return subprocess.run(['tmux', '-L', self.socket, *args], env=self.env,
                              text=True, capture_output=True, check=check)

    def test_supported_commands_preserve_arguments_output_and_exit_status(self):
        self.env['TEST_SUPPORTED'] = '1'
        for command in ('chain', 'main-sequence'):
            sibling = self.directory / ('tmux-agents-' + command)
            sibling.write_text('#!/bin/sh\nexit 99\n')
            sibling.chmod(0o755)
        for script, command in [('tmux-chain', 'chain'), ('tmux-main-sequence', 'main-sequence')]:
            for args in [('--help',), ('path with spaces', '--main-resume', 'abc')]:
                with self.subTest(script=script, args=args):
                    result = self.run_launcher(script, *args)
                    self.assertEqual(result.returncode, 7)
                    self.assertEqual(json.loads(result.stdout), [command, *args])
                    self.assertEqual(result.stderr, '')

    def test_unsupported_commands_keep_legacy_help_and_argument_errors(self):
        for script in ('tmux-chain', 'tmux-main-sequence'):
            with self.subTest(script=script):
                result = self.run_launcher(script, '--help')
                self.assertEqual(result.returncode, 0)
                self.assertIn('Usage: ' + script, result.stdout)
                self.assertEqual(result.stderr, '')
                result = self.run_launcher(script, '--unknown-test-flag')
                self.assertEqual(result.returncode, 2)
                self.assertIn('unknown', result.stderr)
                self.assertFalse((self.directory / 'calls').exists())

    def test_legacy_launch_and_existing_sequence_use_only_private_socket(self):
        self.tmux('-f', '/dev/null', 'new-session', '-d', '-s', 'legacy-test')
        self.addCleanup(lambda: self.tmux('kill-server', check=False))
        result = self.run_launcher('tmux-main-sequence', '--no-attach')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.env['TMUX_MAIN_SEQUENCE_AGENT'] = ':'
        result = self.run_launcher('tmux-chain', str(self.directory), '--no-save',
                                   '--target', 'legacy-test', '--name', 'legacy window')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertRegex(result.stdout, r'^%\d+\n$')
        window = self.tmux('display-message', '-p', '-t', result.stdout.strip(), '#{window_name}')
        self.assertEqual(window.stdout.strip(), 'legacy window')
        self.assertFalse((self.directory / 'projects').exists())


if __name__ == '__main__':
    unittest.main(verbosity=2)
