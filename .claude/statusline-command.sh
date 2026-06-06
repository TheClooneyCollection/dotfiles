#!/bin/sh
# Claude Code status line — mirrors fish_prompt style

# Daily token limit (adjust to match your plan)
DAILY_TOKEN_LIMIT=1800000

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name // ""')
ctx_used=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
ctx_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
ctx_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
session_id=$(echo "$input" | jq -r '.session_id // ""')
session_tokens=$(echo "$input" | jq -r '
  (.context_window.total_input_tokens // 0) +
  (.context_window.total_output_tokens // 0)')

# Shorten the path like fish's prompt_pwd (show last 2 components)
short_cwd=$(basename "$cwd")

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
if [ -n "$ctx_pct" ] && [ -n "$ctx_size" ]; then
  pct_int=$(printf "%.0f" "$ctx_pct")
  ctx_used_derived=$(( ctx_size * pct_int / 100 ))
  if [ "$ctx_used_derived" -ge 1000000 ]; then
    ctx_used_str="$(( ctx_used_derived / 1000000 ))M"
  elif [ "$ctx_used_derived" -ge 1000 ]; then
    ctx_used_str="$(( ctx_used_derived / 1000 ))k"
  else
    ctx_used_str="$ctx_used_derived"
  fi
  if [ "$ctx_size" -ge 1000000 ]; then
    ctx_size_str="$(( ctx_size / 1000000 ))M"
  elif [ "$ctx_size" -ge 1000 ]; then
    ctx_size_str="$(( ctx_size / 1000 ))k"
  else
    ctx_size_str="$ctx_size"
  fi
  if [ "$pct_int" -ge 65 ]; then
    ctx_color="\033[0;31m"
  elif [ "$pct_int" -ge 35 ]; then
    ctx_color="\033[0;33m"
  else
    ctx_color="\033[0;32m"
  fi
  ctx_part=$(printf " ${ctx_color}ctx:%s/%s %s%%\033[0m" "$ctx_used_str" "$ctx_size_str" "$pct_int")
fi

# daily token usage bar
daily_file="$HOME/.claude/daily_usage.json"
today=$(date +%Y-%m-%d)
daily_total=0

if [ -n "$session_id" ] && [ "$session_tokens" -gt 0 ] 2>/dev/null; then
  if [ -f "$daily_file" ]; then
    file_date=$(jq -r '.date // ""' "$daily_file" 2>/dev/null)
    if [ "$file_date" = "$today" ]; then
      tmp="${daily_file}.tmp.$$"
      jq --arg sid "$session_id" --argjson tok "$session_tokens" \
        '.sessions[$sid] = $tok' "$daily_file" > "$tmp" && mv "$tmp" "$daily_file"
    else
      printf '{"date":"%s","sessions":{"%s":%s}}' "$today" "$session_id" "$session_tokens" > "$daily_file"
    fi
  else
    printf '{"date":"%s","sessions":{"%s":%s}}' "$today" "$session_id" "$session_tokens" > "$daily_file"
  fi
fi

if [ -f "$daily_file" ]; then
  file_date=$(jq -r '.date // ""' "$daily_file" 2>/dev/null)
  if [ "$file_date" = "$today" ]; then
    daily_total=$(jq '[.sessions | to_entries[] | .value] | add // 0' "$daily_file" 2>/dev/null || echo 0)
  fi
fi

# Build bar (8 blocks)
bar_width=8
filled=$(( daily_total * bar_width / DAILY_TOKEN_LIMIT ))
[ "$filled" -gt "$bar_width" ] && filled=$bar_width
empty=$(( bar_width - filled ))
bar=""
i=0; while [ $i -lt $filled ]; do bar="${bar}█"; i=$((i+1)); done
i=0; while [ $i -lt $empty  ]; do bar="${bar}░"; i=$((i+1)); done

# Format count: e.g. 125k
if [ "$daily_total" -ge 1000 ]; then
  daily_str="$(( daily_total / 1000 ))k"
else
  daily_str="$daily_total"
fi

# Pick bar colour: green < 50%, yellow < 80%, red >= 80%
bar_pct=$(( daily_total * 100 / DAILY_TOKEN_LIMIT ))
if [ "$bar_pct" -ge 80 ]; then
  bar_color="\033[0;31m"   # red
elif [ "$bar_pct" -ge 50 ]; then
  bar_color="\033[0;33m"   # yellow
else
  bar_color="\033[0;32m"   # green
fi

daily_part=$(printf " ${bar_color}[%s]%s\033[0m" "$bar" "$daily_str")

# model (shortened)
model_short=$(echo "$model" | sed 's/Claude //')

# time
time_str=$(date +%H:%M)

printf "%s \033[0;36m%s\033[0m\033[0;90m@%s\033[0m \033[0;34m%s\033[0m%s\033[0;90m [%s]%s\033[0m \033[0;90m%s\033[0m" \
  "$ctx_part" "$user" "$host" "$short_cwd" "$git_part" "$model_short" "$daily_part" "$time_str"
