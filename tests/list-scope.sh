#!/usr/bin/env bash
# Window ancestry, global pinned attention and scoped closed records.
set -eu
here="$(cd "$(dirname "$0")/.." && pwd)"
B="$here/bin"
sock="tmux-agents-test-$$"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/tmux-agents-test.XXXXXX")"
unset TMUX TMUX_PANE CLAUDECODE TMUX_AGENTS_KIND TMUX_AGENTS_PINNED
export XDG_STATE_HOME="$tmp/state"
tmux -L "$sock" -f /dev/null new-session -d -s work -x 160 -y 60 -c "$tmp" cat
tmux -L "$sock" has-session 2>/dev/null || { echo 'ABORT: test server not up'; exit 1; }
S="$(tmux -L "$sock" display-message -p '#{socket_path}')"
case "$S" in ''|*/default) echo "ABORT: unsafe socket '$S'"; tmux -L "$sock" kill-server; exit 1 ;; esac
export TMUX="$S,1,0"
cleanup() { tmux -L "$sock" kill-server 2>/dev/null || true; rm -rf "$tmp"; }
trap cleanup EXIT
tmux set -g default-shell /bin/sh
fail=0
check() { local label="$1"; shift; if "$@"; then echo "ok    $label"; else echo "FAIL  $label"; fail=1; fi; }
agent() { tmux set -p -t "$1" @agent "$2"; [ -z "${3:-}" ] || tmux set -p -t "$1" @parent "$3"; }
has() { grep -q "^$2 " "$1"; }
lacks() { ! has "$@"; }
agent %0 main-a
split="$(tmux split-window -d -h -t %0 -P -F '#{pane_id}' cat)"; agent "$split" split-a %0
main_b="$(tmux new-window -d -t work:1 -c "$tmp" -P -F '#{pane_id}' cat)"; agent "$main_b" main-b
empty="$(tmux new-window -d -t work:2 -c "$tmp" -P -F '#{pane_id}' cat)"
hidden="$(tmux new-session -d -s agents-project-a -c "$tmp" -P -F '#{pane_id}' cat)"; agent "$hidden" hidden-a %0
grand="$(tmux new-window -d -t agents-project-a -c "$tmp" -P -F '#{pane_id}' cat)"; agent "$grand" grand-a "$hidden"
other="$(tmux new-session -d -s agents-project-b -c "$tmp" -P -F '#{pane_id}' cat)"; agent "$other" hidden-b "$main_b"
need="$(tmux new-window -d -t agents-project-b -c "$tmp" -P -F '#{pane_id}' cat)"; agent "$need" needs-b "$other"
perm="$(tmux new-window -d -t agents-project-b -c "$tmp" -P -F '#{pane_id}' cat)"; agent "$perm" permission-b "$main_b"
now="$(date +%s)"
tmux set -p -t "$need" @state needs_you; tmux set -p -t "$need" @attention_since "$((now-300))"
tmux set -p -t "$perm" @perm_since "$((now-100))"
tmux set -p -t "$need" @activity 'waiting for a decision'
# A real client supplies its active window, while reloads run in a hidden pane.
mkfifo "$tmp/input"
exec 9<>"$tmp/input"
tmux -C attach-session -t work:0 <"$tmp/input" >"$tmp/client.log" 2>&1 &
for i in {1..50}; do
  client="$(tmux list-clients -F '#{client_name}' | head -1)"
  [ -z "$client" ] || break
  sleep 0.1
done
[ -n "$client" ] || { echo 'FAIL no test client'; exit 1; }
export TMUX_AGENTS_LIST_CLIENT="$client" TMUX_PANE="$other"
list() { FZF_PROMPT="$1" "$B/tmux-agents" --list | tr '\0' '\n' >"$2"; }
list 'agents · this window> ' "$tmp/local"
for p in "$split" "$hidden" "$grand"; do check "local includes descendant $p" has "$tmp/local" "$p"; done
for p in %0 "$main_b" "$other"; do check "sub view excludes $p" lacks "$tmp/local" "$p"; done
check 'other-window needs-you is pinned' has "$tmp/local" "$need"
check 'other-window permission is pinned' has "$tmp/local" "$perm"
check 'pinned section appears first' test "$(awk '/^%/ {print $1; exit}' "$tmp/local")" = "$need"
check 'waiting time wins over permission severity' test "$(awk '/^%/ {n++; if(n==2) {print $1; exit}}' "$tmp/local")" = "$perm"
check 'pinned heading present' grep -q '▸ needs you' "$tmp/local"
location="$(tmux display-message -p -t "$main_b" '#{session_name}:#{window_index}')"
check 'hidden grandchild shows visible ancestor window, project and activity' grep -q "$location · project-b · waiting for a decision" "$tmp/local"
check 'pinned agent appears only once' test "$(grep -c "^$need " "$tmp/local")" = 1
# Visible splits use their own window, even with a parent elsewhere.
tmux set -p -t "$split" @state needs_you; tmux set -p -t "$split" @activity split-wait
tmux set -p -t "$split" @parent "$main_b"
list 'agents · this window> ' "$tmp/split-pin"
split_location="$(tmux display-message -p -t "$split" '#{session_name}:#{window_index}')"
check 'pinned split uses its own visible window' grep -q "$split_location · .* · split-wait" "$tmp/split-pin"
tmux set -pu -t "$split" @state; tmux set -p -t "$split" @parent %0
own_location="$(tmux display-message -p -t "$need" '#{session_name}:#{window_index}')"
tmux set -p -t "$other" @parent %999999
list 'agents · this window> ' "$tmp/broken-pin"
check 'missing visible ancestor falls back to own window' grep -q "$own_location · project-b · waiting for a decision" "$tmp/broken-pin"
tmux set -pu -t "$other" @parent
list 'agents · this window> ' "$tmp/hidden-pin"
check 'entirely hidden ancestry falls back to own window' grep -q "$own_location · project-b · waiting for a decision" "$tmp/hidden-pin"
tmux set -p -t "$other" @parent "$need"
list 'agents · this window> ' "$tmp/cycle-pin"
check 'hidden parent cycle falls back to own window' grep -q "$own_location · project-b · waiting for a decision" "$tmp/cycle-pin"
tmux set -p -t "$other" @parent "$main_b"
list 'agents · all windows> ' "$tmp/all"
check 'all windows includes other sub agent' has "$tmp/all" "$other"
check 'all windows still pins first' test "$(awk '/^%/ {print $1; exit}' "$tmp/all")" = "$need"
check 'all windows has no duplicate pins' test "$(grep -c "^$perm " "$tmp/all")" = 1
list 'all · this window> ' "$tmp/named"
check 'named local view includes main' has "$tmp/named" %0
check 'named local view excludes other main' lacks "$tmp/named" "$main_b"
check 'named local view still pins globally' has "$tmp/named" "$need"
list 'all · all windows> ' "$tmp/named-all"
check 'named all-window view includes other main' has "$tmp/named-all" "$main_b"
# Records refer to a live direct parent, possibly itself a hidden descendant.
records="$XDG_STATE_HOME/tmux-agents/$(basename "$S")/sessions"; mkdir -p "$records"
record() { printf 'kind=claude\nid=test-id\ndir=%s\nparent=%s\ndepth=1\nclosed=%s\n' "$tmp" "$2" "$now" >"$records/$1"; }
record closed-a main-a; record closed-grand hidden-a; record closed-b main-b; record orphan gone
list 'agents · this window> ' "$tmp/closed"
check 'local closed parent is included' has "$tmp/closed" closed:closed-a
check 'hidden local parent includes closed child' has "$tmp/closed" closed:closed-grand
check 'remote closed parent is excluded' lacks "$tmp/closed" closed:closed-b
check 'missing closed parent is excluded' lacks "$tmp/closed" closed:orphan
list 'agents · all windows> ' "$tmp/closed-all"
check 'all windows includes remote closed agent' has "$tmp/closed-all" closed:closed-b
check 'all windows includes orphan record' has "$tmp/closed-all" closed:orphan
# A cycle and a missing parent do not hang or inherit an unrelated window.
agent "$other" hidden-b "$perm"; tmux set -p -t "$perm" @parent "$other"
list 'agents · this window> ' "$tmp/cycle"
check 'unrelated cycle stays outside local scope' lacks "$tmp/cycle" "$other"
tmux set -pu -t "$need" @state; tmux set -pu -t "$perm" @perm_since
tmux switch-client -c "$client" -t "$empty"
list 'agents · this window> ' "$tmp/empty"
check 'empty window retains column header' grep -q '^ID .*NAME' "$tmp/empty"
check 'empty window advertises scope toggle' grep -q 'ctrl-t: all windows' "$tmp/empty"
check 'empty window has no selectable rows' test "$(wc -l <"$tmp/empty" | tr -d ' ')" = 1
# Independent dimensions, no remembered window scope.
a="$("$B/tmux-agents" --toggle 'agents · all windows> ')"
check 'ctrl-a preserves all-window scope' test "$a" = "change-prompt(all · all windows> )+reload('$B/tmux-agents' --list)"
a="$("$B/tmux-agents" --toggle-scope 'all · this window> ')"
check 'ctrl-t preserves named-pane mode' test "$a" = "change-prompt(all · all windows> )+reload('$B/tmux-agents' --list)"
a="$("$B/tmux-agents" --toggle-scope 'all · all windows> ')"
check 'ctrl-t returns to this window' test "$a" = "change-prompt(all · this window> )+reload('$B/tmux-agents' --list)"
# Exercise the picker wiring with fake UI endpoints, preserving real list reads.
mkdir "$tmp/ui"
export SCOPE_UI_ARGS="$tmp/ui-args" SCOPE_UI_LOG="$tmp/ui-log"
export SCOPE_REAL_TMUX="$(command -v tmux)" SCOPE_PICK="$hidden"
cat >"$tmp/ui/fzf" <<'STUB'
#!/bin/sh
if [ "${SCOPE_REAL_PICKER:-}" = 1 ]; then exec "$SCOPE_REAL_FZF" "$@"; fi
cat >/dev/null
printf '%s\n' "$@" >"$SCOPE_UI_ARGS"
[ "${SCOPE_UI_ABORT:-}" != 1 ] || exit 1
printf 'enter\nall · all windows> \n%s hidden-a\n' "$SCOPE_PICK"
STUB
cat >"$tmp/ui/tmux" <<'STUB'
#!/bin/sh
case "$1" in
  run-shell) printf '%s\n' "$*" >"$SCOPE_UI_LOG"; exit 0 ;;
  -S) exit 0 ;; # Stub only the nested viewer attachment.
esac
exec "$SCOPE_REAL_TMUX" "$@"
STUB
chmod +x "$tmp/ui/fzf" "$tmp/ui/tmux"
PATH="$tmp/ui:$PATH" "$B/tmux-agents" --client "$client" </dev/null
check 'fresh open starts on this window' grep -q '^--prompt=all · this window> $' "$SCOPE_UI_ARGS"
check 'picker wires ctrl-t to scope transform' grep -q 'ctrl-t:transform:.*--toggle-scope' "$SCOPE_UI_ARGS"
check 'accepted prompt carries both scopes into popup' grep -q -- "--view $hidden $client all all" "$SCOPE_UI_LOG"
SCOPE_UI_ABORT=1 PATH="$tmp/ui:$PATH" "$B/tmux-agents" --view "$hidden" "$client" all all </dev/null
check 'return from viewer keeps both dimensions' grep -q '^--prompt=all · all windows> $' "$SCOPE_UI_ARGS"
check 'return from viewer selects the same agent' grep -q 'load:pos(' "$SCOPE_UI_ARGS"
# Real fzf smoke test: the emitted prompt must survive transform/accept.
if command -v fzf >/dev/null 2>&1; then
  cat >"$tmp/picker" <<'STUB'
#!/bin/sh
export PATH="$SCOPE_UI_DIR:$PATH"
"$SCOPE_BIN/tmux-agents" --client "$SCOPE_CLIENT" >"$SCOPE_RESULT" 2>&1
printf '%s' "$?" >"$SCOPE_DONE"
STUB
  chmod +x "$tmp/picker"
  rm -f "$SCOPE_UI_LOG"
  ui="$(tmux new-window -d -t work -P -F '#{pane_id}' \
    -e "SCOPE_UI_DIR=$tmp/ui" -e "SCOPE_REAL_PICKER=1" -e "SCOPE_REAL_FZF=$(command -v fzf)" \
    -e "SCOPE_REAL_TMUX=$SCOPE_REAL_TMUX" -e "SCOPE_UI_LOG=$SCOPE_UI_LOG" \
    -e "XDG_STATE_HOME=$XDG_STATE_HOME" -e "SCOPE_BIN=$B" -e "SCOPE_CLIENT=$client" \
    -e "SCOPE_RESULT=$tmp/picker-result" -e "SCOPE_DONE=$tmp/picker-done" "$tmp/picker")"
  wait_prompt() {
    local i
    for i in {1..100}; do
      if tmux capture-pane -p -t "$ui" 2>/dev/null | grep -q "$1"; then return 0; fi
      [ ! -f "$tmp/picker-done" ] || break
      sleep 0.1
    done
    return 1
  }
  check 'real picker opens local' wait_prompt 'all · this window>'
  tmux send-keys -t "$ui" C-t
  check 'real ctrl-t switches scope' wait_prompt 'all · all windows>'
  tmux send-keys -t "$ui" C-a
  check 'real ctrl-a keeps scope' wait_prompt 'agents · all windows>'
  tmux send-keys -l -t "$ui" hidden-a
  check 'real reload finishes before selection' wait_prompt 'hidden-a.*working.*main-a'
  tmux send-keys -t "$ui" Enter
  for i in {1..100}; do [ ! -f "$tmp/picker-done" ] || break; sleep 0.1; done
  check 'real picker accepts without error' test "$(cat "$tmp/picker-done" 2>/dev/null)" = 0
  check 'real Enter forwards final scope to viewer' grep -q -- "--view $hidden $client all sub" "$SCOPE_UI_LOG"
else
  echo 'SKIP real picker smoke test (fzf not installed)'
fi
[ "$fail" -eq 0 ] && echo 'all passed' || echo 'some failed'
exit "$fail"
