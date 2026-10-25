#!/usr/bin/env python3
"""Integration checks using an isolated tmux server and an attached PTY client."""
import json
import os
from pathlib import Path
import pty
import subprocess
import tempfile
import time
import unittest
import uuid

ROOT = Path(__file__).resolve().parents[2]
PICKER = ROOT / '.bin/tmux-window-picker'


class PickerTest(unittest.TestCase):
    def tmux(self, *args):
        return subprocess.check_output(['tmux', '-L', self.socket, *args], text=True).strip()

    def setUp(self):
        self.socket = 'picker-test-' + uuid.uuid4().hex
        self.tmp = tempfile.TemporaryDirectory(prefix='picker-test-')
        self.env = dict(os.environ, TERM='xterm-256color')
        self.env.pop('TMUX', None)
        self.env.pop('TMUX_PANE', None)
        subprocess.run(['tmux', '-L', self.socket, '-f', '/dev/null', 'new-session', '-d', '-s', 'alpha', '-n', 'one'], env=self.env, check=True)
        hooks = '\n'.join(line for line in (ROOT / '.tmux.conf').read_text().splitlines() if line.startswith('set-hook') and '[719]' in line)
        config = Path(self.tmp.name) / 'hooks.conf'
        config.write_text(hooks)
        self.tmux('source-file', str(config))
        self.one = self.tmux('display-message', '-p', '-t', 'alpha:0', '#{window_id}')
        self.two = self.tmux('new-window', '-d', '-t', 'alpha', '-n', 'two', '-P', '-F', '#{window_id}')
        self.beta = self.tmux('new-session', '-d', '-s', 'beta', '-P', '-F', '#{window_id}')
        self.hidden = self.tmux('new-session', '-d', '-s', 'agents-test', '-P', '-F', '#{window_id}')
        self.master, slave = pty.openpty()
        self.client_process = subprocess.Popen(['tmux', '-L', self.socket, 'attach', '-t', 'alpha'], stdin=slave, stdout=slave, stderr=slave, env=self.env)
        os.close(slave)
        for _ in range(100):
            self.client = self.tmux('list-clients', '-F', '#{client_name}')
            if self.client:
                break
            time.sleep(.02)
        self.assertTrue(self.client)

    def tearDown(self):
        subprocess.run(['tmux', '-L', self.socket, 'kill-server'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.client_process.wait(timeout=5)
        os.close(self.master)
        self.tmp.cleanup()

    def visit(self, target):
        self.tmux('switch-client', '-c', self.client, '-t', target)
        # Wait for the synchronous run-shell hook to finish recording.
        for _ in range(100):
            value = self.tmux('show-option', '-wqv', '-t', target, '@window_picker_score')
            if value:
                return float(value.split()[1])
            time.sleep(.02)
        self.fail('visit hook did not record ' + target)

    def test_decay_and_rapid_revisit_coalescing(self):
        target = 'alpha:' + self.one
        previous_time = time.time() - 15 * 60
        self.tmux('set-option', '-w', '-t', target, '@window_picker_score', f'8 {previous_time}')
        subprocess.run([str(PICKER), '-L', self.socket, '--record', target], env=self.env, check=True)
        recorded = self.tmux('show-option', '-wqv', '-t', target, '@window_picker_score')
        value, updated = map(float, recorded.split())
        expected = 8 * 0.5 ** ((updated - previous_time) / 900) + 1
        self.assertAlmostEqual(value, expected, places=8)
        self.assertEqual(float(self.tmux('show-option', '-wqv', '-t', target, '@window_picker_last')), updated)
        subprocess.run([str(PICKER), '-L', self.socket, '--record', target], env=self.env, check=True)
        self.assertEqual(self.tmux('show-option', '-wqv', '-t', target, '@window_picker_score'), recorded)
        # The last-visit stamp is never coalesced.
        self.assertGreater(float(self.tmux('show-option', '-wqv', '-t', target, '@window_picker_last')), updated)

    def test_idle_history_keeps_order_without_mutating_scores(self):
        self.visit('alpha:' + self.one)
        time.sleep(.1)
        unvisited = self.tmux('new-window', '-d', '-t', 'alpha', '-P', '-F', '#{window_id}')
        stub = Path(self.tmp.name) / 'fzf'
        stub.write_text('#!/bin/sh\ncat > "$PICKER_REPORT"\nexit 1\n')
        stub.chmod(0o755)
        report = Path(self.tmp.name) / 'idle-rows'
        env = dict(self.env, PATH=self.tmp.name + os.pathsep + os.environ['PATH'], PICKER_REPORT=str(report))
        for idle in (20 * 60, 12 * 3600, 30 * 86400):
            with self.subTest(idle_seconds=idle):
                now = time.time()
                records = {self.one: f'1 {now-idle}', self.two: f'8 {now-idle}', self.beta: f'4 {now-idle-900}'}
                for window, record in records.items():
                    self.tmux('set-option', '-w', '-t', window, '@window_picker_score', record)
                subprocess.run([str(PICKER), '-L', self.socket, '--client', self.client], env=env, check=True)
                windows = [r.split('\t')[0].split(':')[1] for r in report.read_text().splitlines()]
                self.assertEqual(windows, [self.two, self.beta, self.one, unvisited])
                for window, record in records.items():
                    self.assertEqual(self.tmux('show-option', '-wqv', '-t', window, '@window_picker_score'), record)

    def test_weighted_history_hooks_toggle_preview_and_switch(self):
        second = self.visit('alpha:' + self.two)
        third = self.visit('beta:' + self.beta)
        self.assertGreater(third, second)
        self.assertEqual(float(self.tmux('show-option', '-wqv', '-t', self.beta, '@window_picker_last')), third)
        self.tmux('switch-client', '-c', self.client, '-t', 'alpha:' + self.one)
        time.sleep(.15)
        self.assertTrue(self.tmux('show-option', '-wqv', '-t', self.one, '@window_picker_score'))
        self.assertEqual(self.tmux('show-option', '-wqv', '-t', self.hidden, '@window_picker_score'), '')
        # Even explicit recording must ignore hidden sessions.
        self.tmux('switch-client', '-c', self.client, '-t', 'agents-test')
        time.sleep(.1)
        self.assertEqual(self.tmux('show-option', '-wqv', '-t', self.hidden, '@window_picker_score'), '')
        self.tmux('switch-client', '-c', self.client, '-t', 'alpha:' + self.one)
        self.tmux('new-session', '-d', '-s', 'alpha-group', '-t', 'alpha')
        time.sleep(.1)
        before_popup = self.tmux('show-option', '-wqv', '-t', self.one, '@window_picker_score')
        self.tmux('display-popup', '-c', self.client, '-E', 'true')
        time.sleep(.1)
        self.assertEqual(self.tmux('show-option', '-wqv', '-t', self.one, '@window_picker_score'), before_popup)
        # A detached session cannot alter the window's previous visit stamp.
        subprocess.run([str(PICKER), '-L', self.socket, '--record', 'beta:' + self.beta], env=self.env, check=True)
        self.assertEqual(float(self.tmux('show-option', '-wqv', '-t', self.beta, '@window_picker_score').split()[1]), third)
        # Renaming a window preserves its stable-ID history.
        before_rename = self.tmux('show-option', '-wqv', '-t', self.two, '@window_picker_score')
        self.tmux('rename-window', '-t', self.two, 'renamed')
        self.assertEqual(self.tmux('show-option', '-wqv', '-t', self.two, '@window_picker_score'), before_rename)
        # Recent repeated visits beat an older, larger raw visit count.
        # The current window receives exactly the same scoring treatment.
        now = time.time()
        for window, value, updated in [(self.one, 8, now), (self.two, 4, now), (self.beta, 10, now - 30 * 60)]:
            self.tmux('set-option', '-w', '-t', window, '@window_picker_score', f'{value} {updated}')
        # fzf harness exercises the actual generated transform/reload and preview
        # commands, then selects a different session using the real picker.
        stub = Path(self.tmp.name) / 'fzf'
        stub.write_text('''#!/usr/bin/env python3
import json, os, shlex, subprocess, sys
args=sys.argv[1:]
rows=sys.stdin.read().splitlines()
bind=next(a for a in args if 'ctrl-s:transform:' in a).split('ctrl-s:transform:',1)[1]
place=next(a for a in args if 'load:transform:' in a).split('load:transform:',1)[1]
outputs=[];positions=[]
for prompt in ['Frequent> ', 'windows> ']:
 env=dict(os.environ,FZF_PROMPT=prompt)
 action=subprocess.check_output(['bash','-c',bind],env=env,text=True)
 command=action.split('+reload(',1)[1][:-1]
 outputs.append(subprocess.check_output(['bash','-c',command],text=True).splitlines())
 positions.append(subprocess.check_output(['bash','-c',place],env=env,text=True))
retype=next(a for a in args if 'change:transform:' in a).split('change:transform:',1)[1]
for query in ['ar','']:
 positions.append(subprocess.check_output(['bash','-c',retype],env=dict(os.environ,FZF_PROMPT='Frequent> ',FZF_QUERY=query),text=True))
preview=next(a for a in args if a.startswith('--preview=')).split('=',1)[1]
subprocess.run(['bash','-c',preview.replace('{1}',shlex.quote(rows[0].split('\\t')[0]))],check=True,stdout=subprocess.DEVNULL)
with open(os.environ['PICKER_REPORT'],'w') as f:json.dump([rows,outputs,args,positions],f)
print(rows[-1])
''')
        stub.chmod(0o755)
        report = Path(self.tmp.name) / 'report.json'
        env = dict(self.env, PATH=self.tmp.name + os.pathsep + os.environ['PATH'], PICKER_REPORT=str(report))
        subprocess.run([str(PICKER), '-L', self.socket, '--client', self.client], env=env, check=True)
        rows, orders, args, positions = json.loads(report.read_text())
        windows = [r.split('\t')[0].split(':')[1] for r in rows]
        self.assertEqual(windows, [self.one, self.two, self.beta])
        # Current is one; beta was visited after two, so the cursor starts on
        # beta: row 3 in Frequent order, row 3 in session order.
        # Typing jumps to the best match; clearing the query returns to beta.
        self.assertEqual(positions, ['pos(3)', 'pos(3)', 'first', 'pos(3)'])
        self.assertEqual(orders[1], rows)
        self.assertEqual([r.split('\t')[0].split(':')[1] for r in orders[0]], [self.one, self.two, self.beta])
        self.assertTrue(all('agents-' not in r and 'alpha-group' not in r for r in rows))
        self.assertEqual(self.tmux('list-clients', '-F', '#{window_id}'), self.beta)
        self.assertIn('--no-sort', args)
        # Switching to a lower-ranked window and reopening keeps the layout;
        # neither being current nor one extra visit overrides history.
        time.sleep(.1)
        subprocess.run([str(PICKER), '-L', self.socket, '--client', self.client], env=env, check=True)
        self.assertEqual(json.loads(report.read_text())[0], rows)
        # Now current is beta and one was the last visited: Frequent row 1, session row 1.
        self.assertEqual(json.loads(report.read_text())[3], ['pos(1)', 'pos(1)', 'first', 'pos(1)'])

        # The installed fzf must accept the generated options and still search
        # the visible label, rather than the hidden stable IDs.
        filtered = subprocess.check_output(['fzf', *args, '--filter=beta'], input='\n'.join(rows) + '\n', text=True, env=self.env)
        self.assertIn('beta:', filtered)
        self.assertEqual(len(filtered.splitlines()), 1)


if __name__ == '__main__':
    unittest.main()
