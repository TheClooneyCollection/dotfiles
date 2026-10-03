#!/usr/bin/env bash
# Regression tests for tmux-spawn --for: main spawns a worker for its
# secondary. The worker must belong to the secondary only, start
# without a task, and keep the depth of whoever spawned it. Runs on an
# isolated tmux server with stub agents.
#
#   tests/spawn-for.sh
set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
B="$here/bin"
sock="tmux-agents-test-$$"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/tmux-agents-test.XXXXXX")"

# Stub agents: print their arguments, then wait like an idle agent.
mkdir -p "$tmp/bin"
for a in claude codex; do
  printf '#!/bin/sh\necho "FAKE %s $*"\nexec cat\n' "$a" > "$tmp/bin/$a"
  chmod +x "$tmp/bin/$a"
done

unset TMUX TMUX_PANE CLAUDECODE TMUX_AGENTS_KIND TMUX_AGENTS_PINNED TMUX_AGENTS_DEPTH
export XDG_STATE_HOME="$tmp/state" TMUX_ASK_ENTER_DELAY=0 TMUX_SPAWN_BIN="$tmp/bin"

tmux -L "$sock" -f /dev/null new-session -d -x 160 -y 40 -c "$tmp" cat
# Never let this reach the user's live server: the test server must be up,
# on a real socket that isn't the default one.
tmux -L "$sock" has-session 2>/dev/null || { echo "ABORT: test server not up"; exit 1; }
S="$(tmux -L "$sock" display -p '#{socket_path}')"
case "$S" in ''|*/default) echo "ABORT: unsafe socket '$S'"; tmux -L "$sock" kill-server; exit 1 ;; esac
export TMUX="$S,1,0"
cleanup() { tmux -L "$sock" kill-server 2>/dev/null; rm -rf "$tmp"; }
trap cleanup EXIT

fail=0
ok() { echo "ok    $1"; }
bad() { echo "FAIL  $1"; fail=1; }
pane_of() { tmux list-panes -a -F '#{pane_id} #{@agent}' | awk -v n="$1" '$2 == n { print $1 }'; }
peers_of() { TMUX_PANE="$1" "$B/tmux-peers" 2>/dev/null | awk 'NR > 2 { print $1 }' | tr '\n' ' '; }

# main (%0, depth 0) and secondary (%1, its depth-1 sub agent), connected.
tmux set -p -t %0 @agent main
CLAUDECODE=1 TMUX_PANE=%0 "$B/tmux-spawn" --name secondary "assist" </dev/null >/dev/null
coord="$(pane_of secondary)"
sleep 0.5

out="$(TMUX_PANE=%0 "$B/tmux-spawn" codex --for secondary --name worker "build the parser" </dev/null)" || bad "spawn --for failed: $out"
sleep 0.8
w="$(pane_of worker)"
[ -n "$w" ] && ok "worker spawned ($w)" || { bad "no worker pane"; exit 1; }
[ "$(tmux show -pqv -t "$w" @state)" = idle ] && ok "worker starts idle" || bad "worker did not start idle"
listing="$(FZF_PROMPT='agents · all windows> ' "$B/tmux-agents" --list | tr '\0' '\n')"
case "$listing" in *"worker"*"○ idle"*) ok "list shows worker idle" ;; *) bad "list did not show worker idle" ;; esac

[ "$(printf '%s\n' "$listing" | awk '/^%/ {print $1; exit}')" = "$coord" ] && ok "working sorts before idle" || bad "idle sorted before working"
tmux set -p -t "$coord" @state done
listing="$(FZF_PROMPT='agents · all windows> ' "$B/tmux-agents" --list | tr '\0' '\n')"
[ "$(printf '%s\n' "$listing" | awk '/^%/ {print $1; exit}')" = "$w" ] && ok "idle sorts before done" || bad "done sorted before idle"
tmux set -p -t "$coord" @state working

# With the worker as the only sub agent, chip focus and counts are deterministic.
tmux set -pu -t "$coord" @parent
chip="$("$B/tmux-agents" --chip)"
case "$chip" in *'#[fg=colour244]○ worker: idle'*) ok "chip focuses idle worker in grey" ;; *) bad "chip idle focus missing" ;; esac
case "$chip" in *'#[fg=colour244]○ 1'*) ok "chip counts idle worker" ;; *) bad "chip idle count missing" ;; esac
tmux set -p -t "$coord" @parent %0
TMUX_PANE=%0 "$B/tmux-spawn" codex --name no-task </dev/null >/dev/null
no_task="$(pane_of no-task)"
[ "$(tmux show -pqv -t "$no_task" @state)" = idle ] && ok "ordinary no-task spawn starts idle" || bad "no-task spawn did not start idle"
TMUX_PANE=%0 "$B/tmux-dismiss" --from main no-task >/dev/null

[ "$(tmux show -pqv -t "$w" @parent)" = "$coord" ] && ok "its parent is the secondary" || bad "parent is $(tmux show -pqv -t "$w" @parent), not $coord"
case " $(peers_of "$w")" in *" secondary "*) ok "connected to the secondary" ;; *) bad "not connected to the secondary" ;; esac
case " $(peers_of "$w")" in *" main "*) bad "connected to main" ;; *) ok "not connected to main" ;; esac
case " $(peers_of %0)" in *" worker "*) bad "main lists the worker as a peer" ;; *) ok "main has no link to it" ;; esac

screen="$(tmux capture-pane -p -J -t "$w" -S -50)"
case "$screen" in *"FAKE codex"*) ok "it runs the requested agent" ;; *) bad "stub agent not started" ;; esac
case "$screen" in *"build the parser"*|*"[request from"*) bad "it got a task" ;; *) ok "it starts without a task" ;; esac

cs="$(tmux capture-pane -p -J -t "$coord" -S -100)"
case "$cs" in *"[request from main to secondary"*"I spawned worker"*) ok "the secondary was told, by main" ;; *) bad "the secondary wasn't told" ;; esac
case "$cs" in *"build the parser"*) ok "with main's brief" ;; *) bad "the brief didn't reach the secondary" ;; esac

[ "$(grep '^depth=' "$XDG_STATE_HOME"/tmux-agents/*/sessions/worker | cut -d= -f2)" = 1 ] && ok "its depth counts from main (1)" || bad "recorded depth is not 1"

TMUX_PANE=%0 "$B/tmux-spawn" codex --for secondary --name ancestor-close "cleanup check" </dev/null >/dev/null
TMUX_PANE=%0 "$B/tmux-dismiss" --from main ancestor-close >/dev/null 2>&1 && ok "main can close its descendant" || bad "main could not close its descendant"
TMUX_PANE="$coord" "$B/tmux-dismiss" --from secondary worker >/dev/null 2>&1 && ok "the secondary can close it" || bad "the secondary couldn't close it"

tmux new-window -d -c "$tmp" cat; other="$(tmux list-panes -a -F '#{pane_id}' | tail -1)"; tmux set -p -t "$other" @agent stranger
TMUX_PANE=%0 "$B/tmux-spawn" codex --for stranger --name w2 </dev/null >/dev/null 2>&1 && bad "spawned for an agent main isn't connected to" || ok "refuses an owner main isn't connected to"

[ "$fail" -eq 0 ] && echo "all passed" || echo "some failed"
exit "$fail"
