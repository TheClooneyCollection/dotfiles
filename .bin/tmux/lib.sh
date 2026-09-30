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
  local pane="${FROM_PANE:-${TMUX_PANE:-}}"
  [ -n "$pane" ] || die "not inside a tmux pane (pass --from <your name>)"
  case "$pane" in
    %*) ;;
    *) pane="$(find_pane "$pane")"; [ -n "$pane" ] || die "no agent named '$FROM_PANE'" ;;
  esac
  pane_alive "$pane" || die "pane $pane no longer exists"
  printf '%s\n' "$pane"
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

is_agents_session() {
  case "$1" in "$AGENTS_PREFIX"-*) return 0 ;; *) return 1 ;; esac
}

# Succeeds if the user seems busy in pane $1: it is in copy mode (they're
# scrolling it, and Enter would go to copy mode), or a client is showing it
# and had a keypress in the last TMUX_ASK_IDLE_SECS (default 8).
user_busy() {
  [ "$(tmux display-message -p -t "$1" '#{pane_in_mode}')" != 1 ] || return 0
  tmux list-clients -F '#{pane_id} #{client_activity}' | awk -v p="$1" -v now="$(date +%s)" \
    -v w="${TMUX_ASK_IDLE_SECS:-8}" '$1 == p && now - $2 < w { f = 1 } END { exit !f }'
}

# Message bodies for tmux-ask. Requests carry their own reply instructions,
# so a receiver that never loaded the skill can still answer.
# Args: sender, message, receiver. The receiver's name goes into the
# reply command as --from, so it works even where TMUX_PANE is wrong.
# Both end with an [end of ...] line: text outside the markers in the same
# prompt was typed by the user (a draft can get submitted along with it).
request_body() {
  printf '[request from %s to %s via tmux-ask]\n%s\n\n(You are %s. When done, send your answer back with: tmux-ask --from %s --reply %s <<'"'"'MSG'"'"'\n<your reply>\nMSG)\n[end of request from %s to %s]' "$1" "$3" "$2" "$3" "$3" "$1" "$1" "$3"
}

reply_body() {
  printf '[reply from %s to %s via tmux-ask]\n%s\n\n(This is a reply. Do not answer it unless you have a new request.)\n[end of reply from %s to %s]' "$1" "$3" "$2" "$1" "$3"
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
    id="$(tmux display-message -p -t "$1" '#{pane_id}' 2>/dev/null)" || id=""
  fi
  [ -n "$id" ] && pane_alive "$id" || die "no pane named or targeted by '$1'"
  printf '%s\n' "$id"
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
      *" $2 "*) die "'$2' was closed by the user. If you still need it, spawn a new sub agent with tmux-spawn and pass along any report paths it gave you." ;;
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
