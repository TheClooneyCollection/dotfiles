#!/usr/bin/env bash
# Subtree dismissal and authorization, using only an isolated tmux server.
set -eu
here="$(cd "$(dirname "$0")/.." && pwd)"
B="$here/bin"
sock="tmux-agents-dismiss-$$"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/tmux-agents-dismiss.XXXXXX")"
mkdir -p "$tmp/bin"
for a in claude codex; do
  printf '#!/bin/sh\necho "FAKE %s $*"\nexec cat\n' "$a" >"$tmp/bin/$a"
  chmod +x "$tmp/bin/$a"
done
unset TMUX TMUX_PANE CLAUDECODE TMUX_AGENTS_KIND TMUX_AGENTS_PINNED TMUX_AGENTS_DEPTH
export XDG_STATE_HOME="$tmp/state" TMUX_ASK_ENTER_DELAY=0 TMUX_SPAWN_BIN="$tmp/bin"
tmux -L "$sock" -f /dev/null new-session -d -s work -x 160 -y 40 -c "$tmp" cat
tmux -L "$sock" has-session 2>/dev/null || { echo 'ABORT: test server not up'; exit 1; }
S="$(tmux -L "$sock" display-message -p '#{socket_path}')"
case "$S" in ''|*/default) echo "ABORT: unsafe socket '$S'"; tmux -L "$sock" kill-server; exit 1 ;; esac
export TMUX="$S,1,0"
cleanup() { tmux -L "$sock" kill-server 2>/dev/null || true; rm -rf "$tmp"; }
trap cleanup EXIT
tmux set -g default-shell /bin/sh
tmux set -p -t %0 @agent main
fail=0
count=0
check() { local label="$1"; shift; count=$((count + 1)); if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fail=1; fi; }
pane_of() { tmux list-panes -a -F '#{pane_id} #{@agent}' | awk -v n="$1" '$2 == n {print $1}'; }
alive() { tmux list-panes -a -F '#{pane_id}' | grep -qx -- "$1"; }
gone() { ! alive "$1"; }
reject() { if "$B/tmux-dismiss" "$@" >"$tmp/error" 2>&1; then return 1; else return 0; fi; }
spawn() { TMUX_PANE=%0 "$B/tmux-spawn" claude --from main "$@" </dev/null >/dev/null; }
tree() {
  spawn --name secondary assist
  secondary="$(pane_of secondary)"
  spawn --for secondary --name worker implement
  worker="$(pane_of worker)"
  TMUX_AGENTS_DEPTH=1 "$B/tmux-spawn" claude --from worker --name child assist </dev/null >/dev/null
  child="$(pane_of child)"
}
records="$XDG_STATE_HOME/tmux-agents/$(basename "$S")/sessions"
tree
check 'worker belongs to secondary via --for' test "$(tmux show -pqv -t "$worker" @parent)" = "$secondary"
check 'child belongs to worker' test "$(tmux show -pqv -t "$child" @parent)" = "$worker"
check 'self dismissal refused' reject --from main main
check 'ancestor dismissal refused' reject --from child secondary
spawn --name stranger assist
stranger="$(pane_of stranger)"
check 'unrelated dismissal refused' reject --from stranger worker
check 'nonexistent caller pane refused' reject --from %999999 worker
check 'unknown target refused' reject --from main missing
tmux set -p -t "$worker" @parent %999999
check 'stale parent refused' reject --from main child
tmux set -p -t "$worker" @parent "$child"
check 'cyclic ancestry refused' reject --from main child
tmux set -p -t "$worker" @parent "$secondary"
"$B/tmux-dismiss" --from main secondary >"$tmp/closed"
printf 'dismissed child (%s)\ndismissed worker (%s)\ndismissed secondary (%s)\n' "$child" "$worker" "$secondary" >"$tmp/expected"
check 'whole subtree printed deepest first' cmp -s "$tmp/expected" "$tmp/closed"
for name in secondary worker child; do
  check "$name is closed" test -z "$(pane_of "$name")"
  check "$name retains session id" grep -Eq '^id=.+' "$records/$name"
  check "$name retains closed timestamp" grep -Eq '^closed=[0-9]+$' "$records/$name"
done
check 'unrelated agent stays alive' alive "$stranger"
"$B/tmux-spawn" --from main --resume child </dev/null >"$tmp/resume"
child="$(pane_of child)"
check 'closed grandchild can resume' alive "$child"
check 'resume removes closed timestamp' test "$(grep -c '^closed=' "$records/child" || true)" = 0
"$B/tmux-dismiss" --from main child >/dev/null
tree
"$B/tmux-dismiss" --from main worker >"$tmp/closed"
check 'main can directly close a grandchild' gone "$worker"
check 'direct grandchild dismissal closes its child' gone "$child"
check 'grandchild dismissal leaves its parent' alive "$secondary"
"$B/tmux-dismiss" secondary >/dev/null
tree
"$B/tmux-dismiss" --from main --keep-children secondary >"$tmp/closed"
check 'keep-children closes target' gone "$secondary"
check 'keep-children preserves direct child' alive "$worker"
check 'keep-children clears direct parent' test -z "$(tmux show -pqv -t "$worker" @parent)"
check 'keep-children preserves deeper ownership' test "$(tmux show -pqv -t "$child" @parent)" = "$worker"
check 'former ancestor cannot close unowned subtree' reject --from main worker
"$B/tmux-dismiss" worker >"$tmp/closed"
check 'plain user dismissal closes subtree root' gone "$worker"
check 'plain user dismissal closes subtree child' gone "$child"
tree
tmux set -p -t "$secondary" @state done
tmux set -p -t "$worker" @state waiting
tmux set -p -t "$child" @state working
"$B/tmux-dismiss" --from main --done >"$tmp/done"
check 'done skips finished parent with active subtree' grep -q 'skipped secondary.*unfinished' "$tmp/done"
check 'done preserves finished parent' alive "$secondary"
check 'done preserves waiting child' alive "$worker"
check 'done preserves working descendant' alive "$child"
# Also verify accepted --done through a real test-server tty.
tmux set -p -t "$worker" @state done
tmux respawn-pane -k -t "$child" 'exit 0'
for i in {1..50}; do
  [ "$(tmux display-message -p -t "$child" '#{pane_dead}')" != 1 ] || break
  sleep 0.05
done
check 'exited process is retained as a dead pane' test "$(tmux display-message -p -t "$child" '#{pane_dead}')" = 1
# Run in a dedicated pane so /dev/tty confirmation never uses the caller tty.
printf '#!/bin/sh\n"%s/tmux-dismiss" --from main --done >"%s/done-confirmed" 2>&1\necho $? >"%s/done-status"\nexec cat\n' "$B" "$tmp" "$tmp" >"$tmp/confirm"
confirm="$(tmux new-window -d -P -F '#{pane_id}' "/bin/sh '$tmp/confirm'")"
for i in {1..100}; do
  if [ -f "$tmp/done-confirmed" ] && grep -q '\[y/N\]' "$tmp/done-confirmed"; then break; fi
  sleep 0.05
done
tmux send-keys -t "$confirm" y Enter
for i in {1..100}; do [ ! -f "$tmp/done-status" ] || break; sleep 0.05; done
check 'confirmed done succeeds' test "$(cat "$tmp/done-status" 2>/dev/null)" = 0
grep -o 'dismissed .*' "$tmp/done-confirmed" >"$tmp/actual"
printf 'dismissed child (%s)\ndismissed worker (%s)\ndismissed secondary (%s)\n' "$child" "$worker" "$secondary" >"$tmp/expected"
check 'done closes overlapping candidates once deepest first' diff -u "$tmp/expected" "$tmp/actual"
check 'done respects caller ownership' alive "$stranger"
[ "$fail" -ne 0 ] || echo "all $count checks passed"
exit "$fail"
