# Shared helpers for the tmux-* agent pairing scripts. Sourced, not executed.
#
# State lives on the panes themselves as tmux user options:
#   @agent  this pane's name (unique across the tmux server)
#   @peers  space-separated pane ids this pane is connected to
# Pane ids (%12) survive pane moves, and the options vanish with the pane.

die() {
  printf '%s: %s\n' "$(basename "$0")" "$*" >&2
  exit 1
}

require_tmux() {
  command -v tmux >/dev/null 2>&1 || die "tmux not found"
  if ! tmux list-sessions >/dev/null 2>&1; then
    [ -n "${TMUX:-}" ] && die "can't reach the tmux server. In Codex this means the command ran in the sandbox: run tmux-* commands on their own (not chained with other commands) so the allow rule applies, or ask for escalated permissions."
    die "no tmux server running"
  fi
}

# display-message -t exits 0 with empty output for a closed pane id, so check the list.
pane_alive() {
  local panes
  panes="$(tmux list-panes -a -F '#{pane_id}')"
  printf '%s\n' "$panes" | grep -qx -- "$1"
}

pane_name() {
  tmux display-message -p -t "$1" '#{@agent}' 2>/dev/null
}

pane_command() {
  tmux display-message -p -t "$1" '#{pane_current_command}' 2>/dev/null
}

pane_location() {
  tmux display-message -p -t "$1" '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null
}

# Print the id of the pane named $1, if any.
find_pane() {
  tmux list-panes -a -F '#{pane_id} #{@agent}' | awk -v n="$1" '$2 == n { print $1; exit }'
}

# The pane this script acts for: --from (a name or pane id), else $TMUX_PANE.
# Codex runs commands in a shared app-server daemon whose TMUX_PANE is the
# pane it started in, so agents pass --from with their own name.
self_pane() {
  local pane="${FROM_PANE:-${TMUX_PANE:-}}" mine
  [ -n "$pane" ] || die "not inside a tmux pane (pass --from <your name>)"
  case "$pane" in
    %*) ;;
    *)
      pane="$(find_pane "$FROM_PANE")"
      if [ -z "$pane" ]; then
        # An unknown --from from a freshly opened, unnamed agent: name its
        # own pane, as long as $TMUX_PANE can be trusted to be that pane.
        mine="${TMUX_PANE:-}"
        if trusted_pane && [ -n "$mine" ] && pane_alive "$mine" && [ -z "$(pane_name "$mine")" ]; then
          auto_name "$mine" >/dev/null || die "couldn't give pane $mine a name"
          pane="$mine"
        elif trusted_pane && [ -n "$mine" ] && [ -n "$(pane_name "$mine")" ]; then
          die "no agent named '$FROM_PANE'; you are $(pane_name "$mine") (pass --from $(pane_name "$mine"))"
        else
          die "no agent named '$FROM_PANE'"
        fi
      fi
      ;;
  esac
  pane_alive "$pane" || die "pane $pane no longer exists"
  printf '%s\n' "$pane"
}

# $TMUX_PANE is this agent's own pane: Claude runs commands in its own
# process, and pinned Codex (tmux-spawn or the fish wrappers) has it set
# per session. Unpinned Codex may see another pane's.
trusted_pane() {
  [ -n "${CLAUDECODE:-}" ] || [ -n "${TMUX_AGENTS_PINNED:-}" ]
}

# Give unnamed pane $1 a generated name (<command>-<dir>-<N>) and print it.
# Unless $2 is "quiet", tell the caller on stderr that this is now its name.
auto_name() {
  local n try
  # Runs inside $(...), where set -e doesn't apply: check every step. Two
  # agents naming themselves at once can pick the same name, so confirm it
  # is ours alone after writing, and move on to the next number if not.
  for try in 1 2 3; do
    n="$(suggest_name "$1")" || return 1
    set_name "$1" "$n" || return 1
    [ "$(tmux list-panes -a -F '#{pane_id} #{@agent}' | awk -v n="$n" '$2 == n && !seen[$1]++' | wc -l | tr -d ' ')" -gt 1 ] || break
    tmux set-option -pu -t "$1" @agent 2>/dev/null || true
    [ "$try" -lt 3 ] || return 1
    sleep "0.$((RANDOM % 5))$((RANDOM % 10))"
  done
  refresh_labels
  [ "${2:-}" = quiet ] || printf '%s: this pane had no name, so it is now "%s"; pass --from %s from now on\n' "$(basename "$0")" "$n" "$n" >&2
  printf '%s\n' "$n"
}

valid_name() {
  case "$1" in
    ''|*[!A-Za-z0-9._~-]*) return 1 ;;
    *) return 0 ;;
  esac
}

# Replace characters names can't hold (spaces, slashes, ...) with '-'.
sanitize_name() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9._~-' '-'
}

# Suggest "<command>-<dir>-<N>" for pane $1: dir is the cwd basename (~ for
# home), N is one past the highest number already used with that prefix.
# Shells are left out of the prefix, since the agent hasn't started yet.
# Extra args count as taken names (suggestions not yet applied).
suggest_name() {
  local pane="$1"; shift
  name_for "$(pane_command "$pane")" "$(tmux display-message -p -t "$pane" '#{pane_current_path}')" "$@"
}

# Name for command $1 running in directory $2; extra args count as taken.
name_for() {
  local cmd="$1" dir="$2" base max
  shift 2
  if [ "$dir" = "$HOME" ]; then
    dir="~"
  else
    dir="$(sanitize_name "$(basename "$dir")")"
  fi
  case "$cmd" in
    bash|zsh|fish|sh|dash|ksh|tcsh|nu|'') base="$dir" ;;
    *) base="$(sanitize_name "$cmd")-$dir" ;;
  esac
  max="$( { tmux list-panes -a -F '#{@agent}'; [ $# -eq 0 ] || printf '%s\n' "$@"; } | awk -v b="$base-" '
    index($0, b) == 1 { n = substr($0, length(b) + 1); if (n ~ /^[0-9]+$/ && n + 0 > m) m = n + 0 }
    END { print m + 0 }')"
  printf '%s-%d\n' "$base" "$((max + 1))"
}

# $1, or $1-2, $1-3... whichever no pane holds yet.
unique_name() {
  local base="$1" name="$1" n=1
  while [ -n "$(find_pane "$name")" ]; do
    n=$((n + 1))
    name="$base-$n"
  done
  printf '%s\n' "$name"
}

# Hidden sub agents live in one session per project: agents-<project>.
# The project is the git root's basename, else the directory's; tmux
# session names can't hold '.' or ':'.
AGENTS_PREFIX="${TMUX_AGENTS_PREFIX:-agents}"
agents_session_for() {
  local dir="$1" root
  root="$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null)" || root="$dir"
  if [ "$root" = "$HOME" ]; then
    printf '%s-home\n' "$AGENTS_PREFIX"
  else
    printf '%s-%s\n' "$AGENTS_PREFIX" "$(printf '%s' "$(basename "$root")" | tr -c 'A-Za-z0-9_-' '-')"
  fi
}

# The project pane $1 belongs to, as in agents-<project>: a hidden sub
# agent's from its session, any other pane's from its directory.
pane_project() {
  local session p
  session="$(tmux display-message -p -t "$1" '#{session_name}')"
  if is_agents_session "$session"; then p="$session"
  else p="$(agents_session_for "$(tmux display-message -p -t "$1" '#{pane_current_path}')")"
  fi
  printf '%s\n' "${p#"$AGENTS_PREFIX"-}"
}

is_agents_session() {
  case "$1" in "$AGENTS_PREFIX"-*) return 0 ;; *) return 1 ;; esac
}

# Succeeds if the user seems busy in pane $1: it is in copy mode (they're
# scrolling it, and Enter would go to copy mode), or a client is showing it
# and had a keypress in the last TMUX_ASK_IDLE_SECS (default 8).
user_busy() {
  [ "$(tmux display-message -p -t "$1" '#{pane_in_mode}')" != 1 ] || return 0
  user_typing "$1"
}

# Succeeds if a client showing pane $1 had a keypress (or scroll) in the
# last TMUX_ASK_IDLE_SECS (default 8).
user_typing() {
  tmux list-clients -F '#{pane_id} #{client_activity}' | awk -v p="$1" -v now="$(date +%s)" \
    -v w="${TMUX_ASK_IDLE_SECS:-8}" '$1 == p && now - $2 < w { f = 1 } END { exit !f }'
}

# Message bodies for tmux-ask. Requests carry their own reply instructions,
# so a receiver that never loaded the skill can still answer.
# Args: sender, message, receiver[, extra reply flags]. The receiver's name
# goes into the reply command as --from, so it works even where TMUX_PANE
# is wrong; $4 adds flags such as --any when the two aren't connected.
# Both end with an [end of ...] line: text outside the markers in the same
# prompt was typed by the user (a draft can get submitted along with it).
request_body() {
  printf '[request from %s to %s via tmux-ask]\n%s\n\n(You are %s. When done, send your answer back with: tmux-ask --from %s%s --reply %s <<'"'"'MSG'"'"'\n<your reply>\nMSG)\n[end of request from %s to %s]' "$1" "$3" "$2" "$3" "$3" "${4:+ $4}" "$1" "$1" "$3"
}

reply_body() {
  printf '[reply from %s to %s via tmux-ask]\n%s\n\n(This is a reply. Do not answer it unless you have a new request.)\n[end of reply from %s to %s]' "$1" "$3" "$2" "$1" "$3"
}

# A notice needs no answer and asks for nothing (e.g. "X connected to you").
notice_body() {
  printf '[notice from %s to %s via tmux-ask]\n%s\n\n(This is a notice. No reply or action is needed; carry on with what you were doing.)\n[end of notice from %s to %s]' "$1" "$3" "$2" "$1" "$3"
}

# Give pane $1 the name $2, refusing names another pane already holds.
set_name() {
  valid_name "$2" || die "invalid name '$2' (use letters, digits, . _ ~ and -)"
  local owner
  owner="$(find_pane "$2")"
  if [ -n "$owner" ] && [ "$owner" != "$1" ]; then
    die "name '$2' is already used by pane $owner"
  fi
  tmux set-option -p -t "$1" @agent "$2"
}

# Print live peer ids of pane $1, one per line, pruning dead ones.
get_peers() {
  local raw id live=""
  raw="$(tmux display-message -p -t "$1" '#{@peers}' 2>/dev/null)"
  for id in $raw; do
    if pane_alive "$id"; then
      live="$live $id"
      printf '%s\n' "$id"
    fi
  done
  live="${live# }"
  if [ "$live" != "$raw" ]; then
    set_peers "$1" "$live"
  fi
}

set_peers() {
  if [ -n "$2" ]; then
    tmux set-option -p -t "$1" @peers "$2"
  else
    tmux set-option -pu -t "$1" @peers 2>/dev/null || true
  fi
}

is_peer() {
  # Capture first: piping into grep -q can SIGPIPE get_peers under pipefail.
  local peers
  peers="$(get_peers "$1")"
  printf '%s\n' "$peers" | grep -qx -- "$2"
}

add_peer() {
  # A live pane with this name is back, so it's no longer "closed".
  local name cur
  name="$(pane_name "$2")"
  cur="$(closed_names "$1")"
  case " $cur " in
    *" $name "*) cur="$(printf '%s\n' "$cur" | awk -v n="$name" '{ for (i = 1; i <= NF; i++) if ($i != n) o = o (o ? " " : "") $i } END { print o }')"
      if [ -n "$cur" ]; then tmux set-option -p -t "$1" @closed "$cur"; else tmux set-option -pu -t "$1" @closed; fi ;;
  esac
  is_peer "$1" "$2" && return 0
  set_peers "$1" "$(get_peers "$1" | tr '\n' ' ')$2"
}

remove_peer() {
  set_peers "$1" "$(get_peers "$1" | grep -vx -- "$2" | tr '\n' ' ' | sed 's/ $//')"
}

# Resolve a name, pane id, or tmux target to a pane id.
resolve_pane() {
  local id
  id="$(find_pane "$1")"
  if [ -z "$id" ]; then
    # Only something that looks like a tmux target goes to tmux: %12, 2,
    # 2.1, work:2, work:2.1. tmux matches anything else loosely, by window
    # name too, so a closed agent's name like "blog.example.io-1" resolved
    # to a pane in a window called "blog.example.io": the message went to
    # whoever was there instead of failing.
    is_target "$1" || die "no agent named '$1' (it may have been closed or renamed; see tmux-peers)"
    id="$(tmux display-message -p -t "$1" '#{pane_id}' 2>/dev/null)" || id=""
  fi
  [ -n "$id" ] && pane_alive "$id" || die "no pane named or targeted by '$1'"
  printf '%s\n' "$id"
}

# Succeeds if $1 is a pane id or a numeric tmux target: %12, 2, 2.1,
# work:2, work:2.1 (session names may hold anything but ':').
is_target() {
  local re='^(%[0-9]+|([^:]+:)?[0-9]+(\.[0-9]+)?)$'
  [[ $1 =~ $re ]]
}

# Space-separated word lists in pane option $2 of pane $1.
add_word() {
  local cur
  cur="$(tmux show-options -pqv -t "$1" "$2" 2>/dev/null)"
  case " $cur " in *" $3 "*) return 0 ;; esac
  tmux set-option -p -t "$1" "$2" "${cur:+$cur }$3"
}

remove_word() {
  local cur
  cur="$(tmux show-options -pqv -t "$1" "$2" 2>/dev/null)"
  cur="$(printf '%s\n' "$cur" | awk -v n="$3" '{ for (i = 1; i <= NF; i++) if ($i != n) o = o (o ? " " : "") $i } END { print o }')"
  if [ -n "$cur" ]; then tmux set-option -p -t "$1" "$2" "$cur"; else tmux set-option -pu -t "$1" "$2" 2>/dev/null || true; fi
}

# Names of agents the user closed that pane $1 was connected to (@closed).
closed_names() {
  tmux show-options -pqv -t "$1" @closed 2>/dev/null
}

# Before killing pane $1: tell each of its peers, passively, that the user
# closed it, so a later tmux-ask gets a clear answer instead of "no pane".
# $2, if given, is the pane doing the closing; it already knows.
note_closed() {
  local name peer cur
  name="$(pane_name "$1")"
  [ -n "$name" ] || return 0
  for peer in $(get_peers "$1"); do
    [ "$peer" != "${2:-}" ] || continue
    cur="$(closed_names "$peer")"
    case " $cur " in *" $name "*) continue ;; esac
    tmux set-option -p -t "$peer" @closed "${cur:+$cur }$name"
  done
}

# Resolve a name to a connected peer of pane $1.
resolve_peer() {
  local id
  if [ -z "$(find_pane "$2")" ]; then
    case " $(closed_names "$1") " in
      *" $2 "*) die "'$2' was closed by the user. Don't reopen it on your own; if the user asks for it back, tmux-spawn --resume $2 brings it back with its conversation. Otherwise, if you still need it, spawn a new sub agent and pass along any report paths it gave you." ;;
    esac
  fi
  id="$(resolve_pane "$2")"
  is_peer "$1" "$id" || die "'$2' is not connected to $(label "$1"). If that isn't you, pass --from <your name> (see tmux-peers)"
  printf '%s\n' "$id"
}

# Pane border label: "name ⇄ peer1, peer2" on named panes, blank on others.
BORDER_FORMAT='#{?#{@agent}, #[bold]#{@agent}#[nobold]#{?#{@peer_names}, ⇄ #{@peer_names}, (not connected)} ,}'

# Store each named pane's peer names in @peer_names for the border label,
# and show a border line only in windows that hold named panes.
refresh_labels() {
  local panes id peer n names win agents
  panes="$(tmux list-panes -a -F '#{pane_id} #{@agent}' | awk 'NF == 2 && !seen[$1]++ { print $1 }')"
  for id in $panes; do
    names=""
    for peer in $(get_peers "$id"); do
      n="$(pane_name "$peer")"
      names="${names:+$names, }${n:-$peer}"
    done
    tmux set-option -p -t "$id" @peer_names "$names"
  done

  for win in $(tmux list-windows -a -F '#{window_id}' | sort -u); do
    agents="$(tmux list-panes -t "$win" -F '#{@agent}')"
    if [ -n "$(printf '%s' "$agents" | tr -d '\n')" ]; then
      tmux set-option -w -t "$win" pane-border-status top
      tmux set-option -w -t "$win" pane-border-format "$BORDER_FORMAT"
      tmux set-option -w -t "$win" @agents_border 1
    elif [ "$(tmux show-options -wqv -t "$win" @agents_border)" = 1 ]; then
      tmux set-option -wu -t "$win" pane-border-status
      tmux set-option -wu -t "$win" pane-border-format
      tmux set-option -wu -t "$win" @agents_border
    fi
  done
}

label() {
  local name
  name="$(pane_name "$1")"
  printf '%s (%s)' "${name:-unnamed}" "$1"
}

# Session records: what it takes to reopen a closed sub agent. One file per
# sub agent name, per tmux server (pane ids and names are per server), as
# key=value lines: kind (claude, codex or a Codex profile), id (the agent's
# session id; Codex's arrives with its first turn end), dir, parent (name),
# depth, closed (epoch, once closed). They outlive the pane, so tmux-spawn
# --resume NAME and the agent list can bring the conversation back.
sessions_dir() {
  local sock="${TMUX%%,*}"
  printf '%s/tmux-agents/%s/sessions\n' "${XDG_STATE_HOME:-$HOME/.local/state}" "$(basename "${sock:-default}")"
}

# record_get NAME KEY: print the value, empty if unset.
record_get() {
  local f
  f="$(sessions_dir)/$1"
  [ -f "$f" ] || return 0
  awk -F= -v k="$2" '$1 == k { sub(/^[^=]*=/, ""); v = $0 } END { printf "%s", v }' "$f"
}

# record_set NAME KEY VALUE: set one key (empty VALUE removes it).
record_set() {
  local d f tmp
  d="$(sessions_dir)"; f="$d/$1"
  mkdir -p "$d"
  tmp="$(mktemp "$d/.rec.XXXXXX")"
  { [ ! -f "$f" ] || awk -F= -v k="$2" '$1 != k' "$f"; [ -z "$3" ] || printf '%s=%s\n' "$2" "$3"; } > "$tmp"
  mv -f "$tmp" "$f"
}

# Mark the sub agent in pane $1 closed, if it has a record.
record_closed() {
  local name
  name="$(pane_name "$1")"
  [ -n "$name" ] && [ -f "$(sessions_dir)/$name" ] || return 0
  record_set "$name" closed "$(date +%s)"
}
