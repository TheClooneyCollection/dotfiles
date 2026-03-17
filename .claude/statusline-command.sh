#!/bin/sh
# Claude Code status line — mirrors fish_prompt style

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name // ""')
used=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten the path like fish's prompt_pwd (show last 2 components)
short_cwd=$(echo "$cwd" | awk -F'/' '{
  n = NF
  if (n <= 2) print $0
  else if (n == 3) printf "%s/%s", $2, $3
  else printf ".../%s/%s", $(n-1), $n
}')

# user@host — cyan/dim
user=$(whoami)
host=$(hostname -s)

# git branch (fast, no locks)
branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
git_part=""
if [ -n "$branch" ]; then
  git_part=$(printf " (\033[0;35m%s\033[0m)" "$branch")
fi

# context usage
ctx_part=""
if [ -n "$used" ]; then
  used_int=$(printf "%.0f" "$used")
  ctx_part=" ctx:${used_int}%"
fi

# model (shortened)
model_short=$(echo "$model" | sed 's/Claude //')

# time
time_str=$(date +%H:%M)

printf "\033[0;36m%s\033[0m\033[0;90m@%s\033[0m \033[0;34m%s\033[0m%s\033[0;90m [%s]%s\033[0m \033[0;32m%s\033[0m" \
  "$user" "$host" "$short_cwd" "$git_part" "$model_short" "$ctx_part" "$time_str"
