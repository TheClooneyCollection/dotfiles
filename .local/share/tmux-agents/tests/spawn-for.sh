#!/usr/bin/env bash
# Regression tests for tmux-spawn --for: main spawns a worker for its
# coordinator. The worker must belong to the coordinator only, start
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

# main (%0, depth 0) and coordinator (%1, its depth-1 sub agent), connected.
tmux set -p -t %0 @agent main
CLAUDECODE=1 TMUX_PANE=%0 "$B/tmux-spawn" --name coordinator "coordinate" </dev/null >/dev/null
coord="$(pane_of coordinator)"
sleep 0.5

out="$(TMUX_PANE=%0 "$B/tmux-spawn" codex --for coordinator --name worker "build the parser" </dev/null)" || bad "spawn --for failed: $out"
sleep 0.8
w="$(pane_of worker)"
[ -n "$w" ] && ok "worker spawned ($w)" || { bad "no worker pane"; exit 1; }

[ "$(tmux show -pqv -t "$w" @parent)" = "$coord" ] && ok "its parent is the coordinator" || bad "parent is $(tmux show -pqv -t "$w" @parent), not $coord"
case " $(peers_of "$w")" in *" coordinator "*) ok "connected to the coordinator" ;; *) bad "not connected to the coordinator" ;; esac
case " $(peers_of "$w")" in *" main "*) bad "connected to main" ;; *) ok "not connected to main" ;; esac
case " $(peers_of %0)" in *" worker "*) bad "main lists the worker as a peer" ;; *) ok "main has no link to it" ;; esac

screen="$(tmux capture-pane -p -J -t "$w" -S -50)"
case "$screen" in *"FAKE codex"*) ok "it runs the requested agent" ;; *) bad "stub agent not started" ;; esac
case "$screen" in *"build the parser"*|*"[request from"*) bad "it got a task" ;; *) ok "it starts without a task" ;; esac

cs="$(tmux capture-pane -p -J -t "$coord" -S -100)"
case "$cs" in *"[request from main to coordinator"*"I spawned worker"*) ok "the coordinator was told, by main" ;; *) bad "the coordinator wasn't told" ;; esac
case "$cs" in *"build the parser"*) ok "with main's brief" ;; *) bad "the brief didn't reach the coordinator" ;; esac

[ "$(grep '^depth=' "$XDG_STATE_HOME"/tmux-agents/*/sessions/worker | cut -d= -f2)" = 1 ] && ok "its depth counts from main (1)" || bad "recorded depth is not 1"

TMUX_PANE=%0 "$B/tmux-dismiss" --from main worker >/dev/null 2>&1 && bad "main could close the coordinator's worker" || ok "main can't close it"
TMUX_PANE="$coord" "$B/tmux-dismiss" --from coordinator worker >/dev/null 2>&1 && ok "the coordinator can close it" || bad "the coordinator couldn't close it"

tmux new-window -d -c "$tmp" cat; other="$(tmux list-panes -a -F '#{pane_id}' | tail -1)"; tmux set -p -t "$other" @agent stranger
TMUX_PANE=%0 "$B/tmux-spawn" codex --for stranger --name w2 </dev/null >/dev/null 2>&1 && bad "spawned for an agent main isn't connected to" || ok "refuses an owner main isn't connected to"

[ "$fail" -eq 0 ] && echo "all passed" || echo "some failed"
exit "$fail"
