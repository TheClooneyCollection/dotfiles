#!/usr/bin/env bash
# Regression tests for how names and tmux targets resolve: a name that no
# longer exists must fail, never land on some other pane through tmux's
# loose target matching. Runs on an isolated tmux server.
#
#   tests/names.sh
set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
B="$here/bin"
sock="tmux-agents-test-$$"
state_dir="$(mktemp -d "${TMPDIR:-/tmp}/tmux-agents-test.XXXXXX")"

unset TMUX TMUX_PANE CLAUDECODE TMUX_AGENTS_KIND TMUX_AGENTS_PINNED
export XDG_STATE_HOME="$state_dir" TMUX_ASK_ENTER_DELAY=0

tmux -L "$sock" -f /dev/null new-session -d -s work -x 120 -y 30 cat
# Never let this reach the user's live server: the test server must be up,
# on a real socket that isn't the default one.
tmux -L "$sock" has-session 2>/dev/null || { echo "ABORT: test server not up"; exit 1; }
S="$(tmux -L "$sock" display -p '#{socket_path}')"
case "$S" in ''|*/default) echo "ABORT: unsafe socket '$S'"; tmux -L "$sock" kill-server; exit 1 ;; esac
export TMUX="$S,1,0"
cleanup() { tmux -L "$sock" kill-server 2>/dev/null; rm -rf "$state_dir"; }
trap cleanup EXIT

# me (%0) in window 0. Window 1 is called blog.example.io and holds
# claude-blog.example.io-1 (%1), connected to me. The agent that used to
# be called blog.example.io-1 is gone.
tmux new-window -d -t work:1 -n blog.example.io cat
tmux set -p -t %0 @agent me; tmux set -p -t %1 @agent claude-blog.example.io-1
TMUX_PANE=%0 "$B/tmux-connect" --from me claude-blog.example.io-1 >/dev/null

fail=0
check() {  # name, then the command; passes if the command's success matches $2
  local name="$1" want="$2"; shift 2
  if "$@" >/dev/null 2>&1; then got=ok; else got=fails; fi
  if [ "$got" = "$want" ]; then echo "ok    $name ($got)"; else echo "FAIL  $name: $got, wanted $want"; fail=1; fi
}
hits() { tmux capture-pane -p -J -t %1 -S -200 | grep -c "$1"; }

check "a closed agent's name fails"            fails env TMUX_PANE=%0 "$B/tmux-ask" blog.example.io-1 "stale-name-test"
check "...with --any too"                      fails env TMUX_PANE=%0 "$B/tmux-ask" --any blog.example.io-1 "stale-any-test"
check "...for tmux-peek"                       fails env TMUX_PANE=%0 "$B/tmux-peek" blog.example.io-1
check "...for tmux-connect (agent mode)"       fails env TMUX_PANE=%0 "$B/tmux-connect" --from me blog.example.io-1
sleep 0.3
n="$(( $(hits stale-name-test) + $(hits stale-any-test) ))"
if [ "$n" -eq 0 ]; then echo "ok    nothing reached the pane in the same-named window"
else echo "FAIL  a message for the closed agent reached %1"; fail=1; fi

check "a name with dots still works"           ok    env TMUX_PANE=%0 "$B/tmux-ask" claude-blog.example.io-1 "dots-test"
check "a pane id works"                        ok    env TMUX_PANE=%0 "$B/tmux-ask" --any %1 "id-test"
check "session:window.pane works"              ok    env TMUX_PANE=%0 "$B/tmux-peek" work:1.0
check "a window number works (connect)"        ok    env TMUX_PANE=%0 "$B/tmux-connect" 1 --as me

[ "$fail" -eq 0 ] && echo "all passed" || echo "some failed"
exit "$fail"
