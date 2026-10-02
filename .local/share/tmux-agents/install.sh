#!/usr/bin/env bash
# Install tmux-agents from this checkout: link the commands and skills, copy
# the Codex rules, and print the lines to add to your own config.
#
#   ./install.sh [--dry-run] [--force]
#
# env: BIN_DIR  where to link the commands (default ~/.local/bin)
#      TMUX_AGENTS_CODEX_HOMES  extra Codex accounts (name=CODEX_HOME ...);
#               their skills and rules are installed too
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
bin_dir="${BIN_DIR:-$HOME/.local/bin}"
dry=0 force=0
for a in "$@"; do
  case "$a" in
    --dry-run) dry=1 ;;
    --force) force=1 ;;
    -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option: $a" >&2; exit 1 ;;
  esac
done

run() { if [ "$dry" -eq 1 ]; then echo "would: $*"; else "$@"; fi; }

# Link $1 at $2, replacing an older link but never a real file unless --force.
link() {
  if [ -L "$2" ] || [ ! -e "$2" ] || [ "$force" -eq 1 ]; then
    run mkdir -p "$(dirname "$2")"
    run ln -sfn "$1" "$2"
    echo "linked $2"
  else
    echo "skipped $2: exists and isn't a link (use --force)" >&2
  fi
}

# Copy $1 to $2 (Codex skips symlinked .rules files).
copy() {
  run mkdir -p "$(dirname "$2")"
  run cp "$1" "$2"
  echo "copied $2"
}

for f in "$here"/bin/tmux-*; do link "$f" "$bin_dir/$(basename "$f")"; done
link "$here/bin/lib.sh" "$bin_dir/lib.sh"

link "$here/skills/claude/tmux-agents" "$HOME/.claude/skills/tmux-agents"
link "$here/skills/tmux-agents-setup" "$HOME/.claude/skills/tmux-agents-setup"

codex_homes="${CODEX_HOME:-$HOME/.codex}"
for e in ${TMUX_AGENTS_CODEX_HOMES:-}; do codex_homes="$codex_homes ${e#*=}"; done
for h in $codex_homes; do
  [ -d "$h" ] || { echo "skipped $h: no such Codex home" >&2; continue; }
  link "$here/skills/codex/tmux-agents" "$h/skills/tmux-agents"
  link "$here/skills/tmux-agents-setup" "$h/skills/tmux-agents-setup"
  copy "$here/integrations/codex/tmux-agents.rules" "$h/rules/tmux-agents.rules"
done

cat <<EOF

Almost done. Add these to your own config:

1. ~/.tmux.conf, then reload tmux:
     %hidden TMUX_AGENTS_BIN="$bin_dir"
     source-file "$here/tmux/tmux-agents.conf"

2. Make sure $bin_dir is on PATH.

3. Claude: merge the "allow" rules from
     $here/integrations/claude/settings.json
   into ~/.claude/settings.json.

4. Codex: start it through a wrapper that pins its tmux identity:
     fish:      cp $here/integrations/fish/functions/*.fish ~/.config/fish/functions/
     bash/zsh:  source $here/integrations/sh/codex.sh   (in ~/.bashrc or ~/.zshrc)

5. Optional: tell your agents to use tmux-spawn instead of built-in sub agents
   (CLAUDE.md / AGENTS.md); the skill describes it.
EOF
