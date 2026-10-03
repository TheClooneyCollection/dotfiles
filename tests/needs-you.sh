#!/usr/bin/env bash
# Regression tests for "needs you": normal workflows must not flag a sub
# agent as needing the user, and a few real cases must. Drives the real
# scripts in an isolated tmux server (never the user's), with `cat` panes
# standing in for agents and Claude hooks / Codex notify simulated by
# calling tmux-agent-report directly.
#
#   tests/needs-you.sh
set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
B="$here/bin"
sock="tmux-agents-test-$$"
state_dir="$(mktemp -d "${TMPDIR:-/tmp}/tmux-agents-test.XXXXXX")"

unset TMUX TMUX_PANE CLAUDECODE TMUX_AGENTS_KIND TMUX_AGENTS_PINNED
export XDG_STATE_HOME="$state_dir" TMUX_ASK_ENTER_DELAY=0

tmux -L "$sock" -f /dev/null new-session -d -x 120 -y 30 cat
# Never let this reach the user's live server: the test server must be up,
# on a real socket that isn't the default one.
tmux -L "$sock" has-session 2>/dev/null || { echo "ABORT: test server not up"; exit 1; }
S="$(tmux -L "$sock" display -p '#{socket_path}')"
case "$S" in ''|*/default) echo "ABORT: unsafe socket '$S'"; tmux -L "$sock" kill-server; exit 1 ;; esac
export TMUX="$S,1,0"
cleanup() { tmux -L "$sock" kill-server 2>/dev/null; rm -rf "$state_dir"; }
trap cleanup EXIT

# boss (%0) and its sub agent kid (%1), connected like tmux-spawn does.
tmux split-window cat
TMUX_PANE=%0 "$B/tmux-connect" %1 --as boss <<< kid >/dev/null
tmux set -p -t %1 @parent %0

fail=0
st() { tmux show -pqv -t "$1" "$2"; }
reset() {
  for p in %0 %1; do
    for o in @attention_since @waiting_on @awaiting @activity @codex_thread; do tmux set -pu -t "$p" "$o" 2>/dev/null; done
  done
  tmux set -p -t %1 @state working
}
# Claude hooks for kid; $1 is the prompt that started the turn.
turn_start() { printf '{"prompt":%s}' "$(printf '%s' "$1" | /usr/bin/perl -MJSON::PP -0777 -ne 'print JSON::PP->new->encode($_)')" | "$B/tmux-agent-report" --pane %1 --turn-start; }
turn_end() { "$B/tmux-agent-report" --pane %1 --turn-end </dev/null; }
notify() {  # thread, last assistant message, input message
  "$B/tmux-agent-report" --codex-notify "$(/usr/bin/perl -MJSON::PP -e 'print JSON::PP->new->encode({type=>"agent-turn-complete","thread-id"=>$ARGV[0],"last-assistant-message"=>$ARGV[1],"input-messages"=>[$ARGV[2]]})' "$@")"
}
ask() { local from="$1"; shift; TMUX_PANE="$from" "$B/tmux-ask" "$@" >/dev/null; }
expect() {  # name, wanted kid state
  local got
  got="$(st %1 @state)"
  if [ "$got" = "$2" ]; then echo "ok    $1 ($got)"; else echo "FAIL  $1: kid is $got, wanted $2"; fail=1; fi
}

echo "Normal workflows: never needs you"

reset
tmux set -p -t %1 @state idle
turn_end
expect "idle without a task stays idle at turn end" idle
"$B/tmux-agent-report" --pane %1 "starting work" >/dev/null
expect "progress report starts idle agent working" working

reset
tmux set -p -t %1 @state idle
ask %0 kid "first task"
expect "first request starts idle agent working" working

reset
ask %0 kid "do x"; turn_start "[request from boss to kid via tmux-ask] do x"
ask %1 --reply boss "done"; turn_end
expect "replies to its parent, then ends its turn" done

reset
ask %0 kid "do z"; turn_start "[request from boss to kid via tmux-ask] do z"
ask %1 --reply boss "delivered abc123"
"$B/tmux-agent-report" --pane %1 "abc123 delivered, all green" >/dev/null; turn_end
expect "replies, then reports progress, then ends its turn" done

turn_start "$(printf '[notice from boss to kid via tmux-ask]\nfyi')"; turn_end
expect "done, then gets a notice" done
[ -z "$(st %0 @awaiting)" ] || { echo "FAIL  a notice made boss wait on kid"; fail=1; }

reset
tmux new-window -d cat; gk="$(tmux list-panes -a -F '#{pane_id}' | tail -1)"
tmux set -p -t "$gk" @agent grandkid; tmux set -p -t "$gk" @parent %1; tmux set -p -t "$gk" @state working
turn_end
expect "waits for its own sub agent" working
tmux kill-pane -t "$gk"

reset
ask %1 boss "question for you"; turn_end
expect "waits for the reply to a request it sent" working

reset
ask %1 --notice boss "progress update"; turn_end
expect "notice to its parent, then ends its turn" working
[ "$(st %1 @waiting_on)" = "boss (after a notice)" ] || { echo "FAIL  missing parent notice wait marker"; fail=1; }
[ "$(st %1 @activity)" = "waiting for boss (after a notice)" ] || { echo "FAIL  missing parent notice wait activity"; fail=1; }
[ -z "$(st %1 @awaiting)" ] || { echo "FAIL  sending a notice created a reply obligation"; fail=1; }

ask %0 --notice kid "acknowledged"
turn_start "[notice from boss to kid via tmux-ask] acknowledged"; turn_end
expect "parent notice wait survives an incoming notice" working

ask %1 --reply boss "done"; turn_end
expect "reply after parent notice stays done" done
ask %1 --notice boss "one last FYI"; turn_end
expect "done agent sends parent notice and stays done" done

reset
# The parent's display name can change; ownership is its pane ID.
tmux set -p -t %0 @agent renamed-boss
ask %1 --any --notice renamed-boss "FYI"; turn_end
expect "notice recognizes parent by pane ID after rename" working
[ "$(st %1 @waiting_on)" = "renamed-boss (after a notice)" ] || { echo "FAIL  notice wait did not use current parent name"; fail=1; }
tmux set -p -t %0 @agent boss

reset
"$B/tmux-agent-report" --pane %1 --waiting "CI run" >/dev/null; turn_end
expect "reported --waiting for background work" working

reset
"$B/tmux-agent-report" --pane %1 --waiting "CI run" >/dev/null
turn_start "$(printf '[notice from boss to kid via tmux-ask]\nfyi')"; turn_end
expect "waiting on background work, then gets a notice" working
[ "$(st %1 @waiting_on)" = "CI run" ] || { echo "FAIL  the notice cleared what kid waits on"; fail=1; }

reset
ask %0 kid "do y"
ask %0 --notice kid "also, fyi"
expect "working, then gets a notice" working

reset
tmux set -p -t %1 @codex_thread main-thread
notify title-thread '{"title":"Do y"}' "[request from boss to kid via tmux-ask] do y"
expect "Codex names its session (title thread)" working
[ "$(st %1 @codex_thread)" = main-thread ] || { echo "FAIL  the title thread replaced @codex_thread"; fail=1; }

reset
tmux set -p -t %1 @codex_thread main-thread; tmux set -p -t %1 @state done
notify main-thread "done, standing by" "anything"
expect "Codex, done, another turn end" done

echo "Real cases: needs you"

reset
ask %1 --notice boss "progress update"; turn_end
ask %0 kid "next task"
[ -z "$(st %1 @waiting_on)" ] || { echo "FAIL  new request retained parent notice wait"; fail=1; }
# No turn_start hook: Codex must also stop waiting on a new request.
turn_end
expect "new request clears parent notice wait without a turn-start hook" needs_you

reset
ask %1 --notice boss "progress update"
"$B/tmux-agent-report" --pane %1 "resumed work" >/dev/null
[ -z "$(st %1 @waiting_on)" ] || { echo "FAIL  progress report retained parent notice wait"; fail=1; }
turn_end
expect "progress report clears parent notice wait" needs_you

reset
tmux new-window -d cat; other="$(tmux list-panes -a -F '#{pane_id}' | tail -1)"
tmux set -p -t "$other" @agent colleague
ask %1 --any --notice colleague "FYI"
[ -z "$(st %1 @waiting_on)" ] || { echo "FAIL  nonparent notice created a wait marker"; fail=1; }
turn_end
expect "notice to a nonparent does not imply waiting" needs_you
tmux kill-pane -t "$other"

reset
"$B/tmux-agent-report" --pane %1 --waiting "CI run" >/dev/null
ask %0 kid "next task"; turn_end
expect "new request clears background wait without a turn-start hook" needs_you

reset
turn_end
expect "ends its turn without replying or waiting" needs_you

reset
"$B/tmux-agent-report" --pane %1 --waiting "CI run" >/dev/null
turn_start "[request from boss to kid via tmux-ask] new task"; turn_end
expect "a new request ends the old wait; no reply" needs_you

reset
tmux set -p -t %1 @state done
ask %0 kid "no reply needed, don't restart"
turn_start "[request from boss to kid via tmux-ask] no reply needed"; turn_end
expect "a request (not a notice) answered only locally" needs_you

[ "$fail" -eq 0 ] && echo "all passed" || echo "some failed"
exit "$fail"
