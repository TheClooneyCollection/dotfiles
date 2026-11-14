#!/usr/bin/env python3
"""Short aliases preserve the tmux-agents command's arguments and results."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class LauncherDelegation(unittest.TestCase):
    def test_wrappers_forward_arguments_output_and_exit_status(self):
        with tempfile.TemporaryDirectory(prefix='tmux-launcher-test-') as directory:
            stub = Path(directory) / 'tmux-agents'
            stub.write_text('''#!/usr/bin/env python3
import json, sys
print(json.dumps(sys.argv[1:]))
print('launcher diagnostic', file=sys.stderr)
sys.exit(7)
''')
            stub.chmod(0o755)
            env = dict(os.environ, PATH=directory + os.pathsep + os.environ['PATH'])
            for script, command in [('tmux-chain', 'chain'), ('tmux-main-sequence', 'main-sequence')]:
                for args in [(), ('--help',), ('path with spaces', '--main-resume', 'abc'),
                             ('set', 'project name', 'resume=abc')]:
                    with self.subTest(script=script, args=args):
                        result = subprocess.run([str(ROOT / '.bin' / script), *args],
                                                env=env, text=True, capture_output=True)
                        self.assertEqual(result.returncode, 7)
                        self.assertEqual(json.loads(result.stdout), [command, *args])
                        self.assertEqual(result.stderr, 'launcher diagnostic\n')


if __name__ == '__main__':
    unittest.main(verbosity=2)
