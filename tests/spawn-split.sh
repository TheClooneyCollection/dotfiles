#!/usr/bin/env bash
# Visible splits, ownership and hidden resume, on an isolated tmux server.
set -eu
here="$(cd "$(dirname "$0")/.." && pwd)"
B="$here/bin"
sock="tmux-agents-test-$$"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/tmux-agents-test.XXXXXX")"
mkdir -p "$tmp/bin"
for a in claude codex; do
  printf '#!/bin/sh\necho "FAKE %s $*"\necho "DEPTH=$TMUX_AGENTS_DEPTH HOMES=$TMUX_AGENTS_CODEX_HOMES"\nexec cat\n' "$a" > "$tmp/bin/$a"
  chmod +x "$tmp/bin/$a"
done
unset TMUX TMUX_PANE CLAUDECODE TMUX_AGENTS_KIND TMUX_AGENTS_PINNED TMUX_AGENTS_DEPTH
export XDG_STATE_HOME="$tmp/state" TMUX_ASK_ENTER_DELAY=0 TMUX_SPAWN_BIN="$tmp/bin"
export TMUX_AGENTS_CODEX_HOMES="extra=$tmp/codex-home"
tmux -L "$sock" -f /dev/null new-session -d -s work -x 160 -y 60 -c "$tmp" cat
# Never fall back to the user's server.
tmux -L "$sock" has-session 2>/dev/null || { echo 'ABORT: test server not up'; exit 1; }
S="$(tmux -L "$sock" display -p '#{socket_path}')"
case "$S" in ''|*/default) echo "ABORT: unsafe socket '$S'"; tmux -L "$sock" kill-server; exit 1 ;; esac
export TMUX="$S,1,0"
cleanup() { tmux -L "$sock" kill-server 2>/dev/null || true; rm -rf "$tmp"; }
trap cleanup EXIT
# Personal fish/zsh startup files must not override the test environment.
tmux set -g default-shell /bin/sh
fail=0
check() { local label="$1"; shift; if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fail=1; fi; }
near() { [ "$1" -ge "$(($2 - 2))" ] && [ "$1" -le "$(($2 + 2))" ]; }
info() { tmux display-message -p -t "$1" "#{$2}"; }
pane_of() { tmux list-panes -a -F '#{pane_id} #{@agent}' | awk -v n="$1" '$2 == n { print $1 }'; }
spawn() { TMUX_PANE=%0 "$B/tmux-spawn" "$@" </dev/null; }
reject() { if spawn "$@" >"$tmp/error" 2>&1; then return 1; else return 0; fi; }
peers() { TMUX_PANE="$1" "$B/tmux-peers" --from "$2"; }
tmux set -p -t %0 @agent main
tmux set -w -t %0 remain-on-exit off
tmux set -w -t %0 automatic-rename on
# Initialize the normal agent border labels before checking spawn options.
"$B/tmux-peers" --refresh >/dev/null
window_options="$(tmux show-options -w -t %0)"
main_options="$(tmux show-options -p -t %0 remain-on-exit)"
main_win="$(info %0 window_id)"
width="$(info %0 pane_width)"
spawn claude --split main --right --name secondary assist >"$tmp/spawn"
secondary="$(pane_of secondary)"
check 'right split is in the target window' test "$(info "$secondary" window_id)" = "$main_win"
check 'right split is to the right' test "$(info "$secondary" pane_left)" -gt "$(info %0 pane_left)"
check 'default size is half the target width' near "$(info "$secondary" pane_width)" "$((width / 2))"
height="$(info "$secondary" pane_height)"
spawn codex --for secondary --split "$secondary" --below --size 40% --name worker 'build the parser' >"$tmp/spawn"
worker="$(pane_of worker)"
check 'worker below secondary is in the same window' test "$(info "$worker" window_id)" = "$main_win"
check 'worker is below secondary' test "$(info "$worker" pane_top)" -gt "$(info "$secondary" pane_top)"
check 'worker and secondary have the same left edge' test "$(info "$worker" pane_left)" = "$(info "$secondary" pane_left)"
check 'below size uses the requested percentage' near "$(info "$worker" pane_height)" "$((height * 40 / 100))"
check 'worker belongs to secondary' test "$(info "$worker" @parent)" = "$secondary"
check 'worker links only to secondary' test "$(info "$worker" @peers)" = "$secondary"
check 'main links only to secondary' test "$(info %0 @peers)" = "$secondary"
check 'detached splits keep main active' test "$(info %0 pane_active)" = 1
check 'main pane remain-on-exit is untouched' test "$(tmux show-options -p -t %0 remain-on-exit)" = "$main_options"
check 'shared window options are untouched' test "$(tmux show-options -w -t %0)" = "$window_options"
check 'secondary has pane-local remain-on-exit' test "$(tmux show-options -pqv -t "$secondary" remain-on-exit)" = on
check 'worker has pane-local remain-on-exit' test "$(tmux show-options -pqv -t "$worker" remain-on-exit)" = on
check 'no hidden session or window was created' test "$(tmux list-windows -a -F '#{window_id}')" = "$main_win"
record="$XDG_STATE_HOME/tmux-agents/$(basename "$S")/sessions/worker"
check 'record keeps caller depth 1' grep -qx 'depth=1' "$record"
check 'record keeps secondary as owner' grep -qx 'parent=secondary' "$record"
# Wait for the stub's startup output without depending on a fixed startup delay.
for i in {1..50}; do
  tmux capture-pane -p -J -t "$worker" -S -100 >"$tmp/screen"
  if grep -q 'DEPTH=1 HOMES=' "$tmp/screen"; then break; fi
  sleep 0.1
done
check 'depth and profiles reach the split process' grep -q "DEPTH=1 HOMES=extra=$tmp/codex-home" "$tmp/screen"
check 'split uses the caller directory' test "$(info "$worker" pane_current_path)" = "$(info %0 pane_current_path)"
check 'worker starts without a task' test "$(grep -c 'build the parser\|\[request from' "$tmp/screen" || true)" = 0
"$B/tmux-agents" --list | tr '\0' '\n' >"$tmp/list"
check 'visible worker appears in the agent list' grep -q "$worker .*worker" "$tmp/list"
check 'visible project comes from the directory' grep -q "$(basename "$tmp")" "$tmp/list"
CHIP_SPIN=x "$B/tmux-agents" --chip >"$tmp/chip"
check 'chip includes visible sub agents' grep -q 'x 2' "$tmp/chip"
peers "$worker" worker >"$tmp/peers"
check 'peers works for the split' grep -q secondary "$tmp/peers"
TMUX_PANE="$secondary" "$B/tmux-ask" --from secondary worker 'split-message-test' >/dev/null
TMUX_PANE="$secondary" "$B/tmux-peek" --from secondary worker 100 >"$tmp/peek"
check 'ask and peek work for the split' grep -q split-message-test "$tmp/peek"
# Exercise Enter's real branch with a fake picker and record client operations.
# Every other tmux command still talks to the verified isolated server.
mkdir "$tmp/ui"
export SPLIT_PICK="$worker" SPLIT_UI_LOG="$tmp/ui.log" SPLIT_REAL_TMUX="$(command -v tmux)"
cat >"$tmp/ui/fzf" <<'STUB'
#!/bin/sh
cat >/dev/null
printf 'enter\nagents · this window> \n%s worker\n' "$SPLIT_PICK"
STUB
cat >"$tmp/ui/tmux" <<'STUB'
#!/bin/sh
case "$1" in
  list-clients) printf 'test-client %s\n' "$("$SPLIT_REAL_TMUX" display-message -p -t %0 '#{window_id}')"; exit 0 ;;
  switch-client) echo "jump $*" >>"$SPLIT_UI_LOG"; exit 0 ;;
  display-message)
    if [ "${2:-}" = -c ]; then exit 0; fi
    if [ "${3:-}" = -c ]; then exec "$SPLIT_REAL_TMUX" display-message -p -t %0 '#{window_id}'; fi ;;
  run-shell|display-popup) echo "popup $*" >>"$SPLIT_UI_LOG"; exit 1 ;;
esac
exec "$SPLIT_REAL_TMUX" "$@"
STUB
chmod +x "$tmp/ui/fzf" "$tmp/ui/tmux"
PATH="$tmp/ui:$PATH" "$B/tmux-agents" --client test-client </dev/null
check 'Enter jumps to a visible split' grep -q "jump switch-client -c test-client -t $worker" "$tmp/ui.log"
check 'Enter does not open a popup' test "$(grep -c popup "$tmp/ui.log" || true)" = 0
for opt in --right --below; do check "$opt needs --split" reject claude "$opt"; done
check '--size needs --split' reject claude --size 30%
check 'unknown split name fails' reject claude --split stale-name
check 'loose window target fails' reject claude --split work:0
check 'invalid size fails' reject claude --split main --size 101%
check 'conflicting directions fail' reject claude --split main --right --below
check 'resume cannot request a split' reject --resume secondary --split main
TMUX_PANE="$secondary" "$B/tmux-dismiss" --from secondary worker >/dev/null
check 'dismiss removes only the worker split' test -z "$(pane_of worker)"
check 'main and secondary remain' test "$(tmux list-panes -t "$main_win" -F '#{pane_id}' | wc -l | tr -d ' ')" = 2
# Claude's recorded id permits resume without simulating a Codex turn.
TMUX_PANE=%0 "$B/tmux-dismiss" --from main secondary >/dev/null
spawn --resume secondary >"$tmp/resume"
reopened="$(pane_of secondary)"
case "$(info "$reopened" session_name)" in agents-*) hidden=yes ;; *) hidden=no ;; esac
check 'dismissed split resumes hidden' test "$hidden" = yes
check 'resume leaves the original window with main only' test "$(tmux list-panes -t "$main_win" -F '#{pane_id}')" = %0
# Default direction is right, and the target can be in another window.
tmux new-window -d -n target -c "$tmp" cat
target="$(tmux list-panes -a -F '#{pane_id} #{window_name}' | awk '$2 == "target" {print $1}')"
target_width="$(info "$target" pane_width)"
spawn claude --split "$target" --size 30% --name right-default >/dev/null
right="$(pane_of right-default)"
check 'default direction splits right in another window' test "$(info "$right" pane_left)" -gt "$(info "$target" pane_left)"
check 'cross-window split lands in target window' test "$(info "$right" window_id)" = "$(info "$target" window_id)"
check 'right size uses requested percentage' near "$(info "$right" pane_width)" "$((target_width * 30 / 100))"
[ "$fail" -eq 0 ] && echo 'all passed' || echo 'some failed'
exit "$fail"
