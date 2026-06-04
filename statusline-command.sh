#!/bin/sh
input=$(cat)

cwd=$(echo "$input" | jq -r '.cwd')
model=$(echo "$input" | jq -r '.model.display_name')

dir=$(basename "$cwd")

branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
fi

if [ -n "$branch" ]; then
  left=$(printf "\033[36m%s\033[0m \033[34mgit:(\033[31m%s\033[34m)\033[0m  🤖 \033[35m%s\033[0m" "$dir" "$branch" "$model")
else
  left=$(printf "\033[36m%s\033[0m  🤖 \033[35m%s\033[0m" "$dir" "$model")
fi

colorize() {
  value=$1
  if [ -z "$value" ]; then
    printf "--"
    return
  fi
  if [ "$value" -ge 80 ]; then
    printf "\033[31m%s%%\033[0m" "$value"
  elif [ "$value" -ge 50 ]; then
    printf "\033[33m%s%%\033[0m" "$value"
  else
    printf "\033[32m%s%%\033[0m" "$value"
  fi
}

five_pct=$(echo "$input" | jq -r '(.rate_limits.five_hour.used_percentage // empty) | round')
week_pct=$(echo "$input" | jq -r '(.rate_limits.seven_day.used_percentage // empty) | round')
ctx_pct=$(echo "$input" | jq -r '(.context_window.used_percentage // empty) | round')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

five_reset_str=""
if [ -n "$five_reset" ]; then
  five_reset_str=$(date -r "$five_reset" "+%H:%M" 2>/dev/null)
fi

week_reset_str=""
if [ -n "$week_reset" ]; then
  week_reset_str=$(date -r "$week_reset" "+%-d %b %H:%M" 2>/dev/null)
fi

printf "%s  ⏰ 5h: %s  📅 7d: %s  🧠 ctx: %s" \
  "$left" \
  "$(colorize "$five_pct")" \
  "$(colorize "$week_pct")" \
  "$(colorize "$ctx_pct")"

[ -n "$five_reset_str" ] && printf "  🔄 5h resets: %s" "$five_reset_str"
[ -n "$week_reset_str" ] && printf "  🌅 week resets: %s" "$week_reset_str"