#!/usr/bin/env bash

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // "."')
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
five_used=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
week_used=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
five_resets_at=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_resets_at=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# --- helper: render a compact progress bar (10 chars wide) ---
# usage: make_bar <percentage_float>  => returns bar string (no color codes, caller wraps)
make_bar() {
  local pct="${1:-0}"
  local width=10
  local filled=$(awk -v p="$pct" -v w="$width" 'BEGIN { v=int(p/100*w+0.5); if(v>w) v=w; print v }')
  local empty=$(( width - filled ))
  local bar=""
  local i
  for (( i=0; i<filled; i++ )); do bar="${bar}▓"; done
  for (( i=0; i<empty;  i++ )); do bar="${bar}░"; done
  echo "$bar"
}

# --- helper: color for percentage (green/yellow/red) ---
pct_color() {
  local pct="${1:-0}"
  local int_pct=$(printf '%.0f' "$pct")
  if   [ "$int_pct" -ge 80 ]; then printf "\033[0;31m"   # red
  elif [ "$int_pct" -ge 50 ]; then printf "\033[0;33m"   # yellow
  else                              printf "\033[0;32m"   # green
  fi
}

# --- git section ---
git_part=""
branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
if [ -n "$branch" ]; then
  status_flags=""
  git_status=$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null)
  if [ -n "$git_status" ]; then
    staged=$(echo "$git_status" | grep -c '^[MADRC]')
    unstaged=$(echo "$git_status" | grep -c '^.[MD]')
    untracked=$(echo "$git_status" | grep -c '^??')
    [ "$staged" -gt 0 ]    && status_flags="${status_flags}\033[0;32m+${staged}\033[0m"
    [ "$unstaged" -gt 0 ]  && status_flags="${status_flags}\033[0;33m~${unstaged}\033[0m"
    [ "$untracked" -gt 0 ] && status_flags="${status_flags}\033[0;31m?${untracked}\033[0m"
  fi
  if [ -n "$status_flags" ]; then
    git_part=$(printf "\033[0;35m%s\033[0m %b" "$branch" "$status_flags")
  else
    git_part=$(printf "\033[0;35m%s\033[0m \033[0;32mclean\033[0m" "$branch")
  fi
else
  git_part=$(printf "\033[0;90mno git\033[0m")
fi

# --- model section ---
model_part=$(printf "\033[0;36m%s\033[0m" "$model")

# --- 5-hour session rate limit progress bar ---
if [ -n "$five_used" ]; then
  five_int=$(printf '%.0f' "$five_used")
  five_bar=$(make_bar "$five_used")
  five_color=$(pct_color "$five_used")
  five_part=$(printf "5h %b%s\033[0m %b%d%%\033[0m" "$five_color" "$five_bar" "$five_color" "$five_int")
else
  five_part=$(printf "\033[0;90m5h --\033[0m")
fi

# --- weekly rate limit progress bar ---
if [ -n "$week_used" ]; then
  week_int=$(printf '%.0f' "$week_used")
  week_bar=$(make_bar "$week_used")
  week_color=$(pct_color "$week_used")
  week_part=$(printf "7d %b%s\033[0m %b%d%%\033[0m" "$week_color" "$week_bar" "$week_color" "$week_int")
else
  week_part=$(printf "\033[0;90m7d --\033[0m")
fi

# --- next session reset time (5-hour window) ---
if [ -n "$five_resets_at" ]; then
  now=$(date +%s)
  diff=$(( five_resets_at - now ))
  if [ "$diff" -le 0 ]; then
    reset_part=$(printf "\033[0;32mreset now\033[0m")
  else
    hrs=$(( diff / 3600 ))
    mins=$(( (diff % 3600) / 60 ))
    reset_time=$(date -d "@${five_resets_at}" +%H:%M 2>/dev/null || date -r "${five_resets_at}" +%H:%M 2>/dev/null)
    if [ "$hrs" -gt 0 ]; then
      reset_part=$(printf "\033[0;90mrst\033[0m \033[0;33m%dh%02dm\033[0m @%s" "$hrs" "$mins" "$reset_time")
    else
      reset_part=$(printf "\033[0;90mrst\033[0m \033[0;33m%dm\033[0m @%s" "$mins" "$reset_time")
    fi
  fi
else
  reset_part=$(printf "\033[0;90mrst --\033[0m")
fi

# --- next weekly reset time (7-day window) ---
if [ -n "$week_resets_at" ]; then
  now=$(date +%s)
  diff=$(( week_resets_at - now ))
  if [ "$diff" -le 0 ]; then
    week_reset_part=$(printf "\033[0;32m7d rst now\033[0m")
  else
    days=$(( diff / 86400 ))
    hrs=$(( (diff % 86400) / 3600 ))
    mins=$(( (diff % 3600) / 60 ))
    reset_time=$(date -d "@${week_resets_at}" +"%a %H:%M" 2>/dev/null || date -r "${week_resets_at}" +"%a %H:%M" 2>/dev/null)
    if [ "$days" -gt 0 ]; then
      week_reset_part=$(printf "\033[0;90m7d rst\033[0m \033[0;33m%dd%02dh\033[0m @%s" "$days" "$hrs" "$reset_time")
    elif [ "$hrs" -gt 0 ]; then
      week_reset_part=$(printf "\033[0;90m7d rst\033[0m \033[0;33m%dh%02dm\033[0m @%s" "$hrs" "$mins" "$reset_time")
    else
      week_reset_part=$(printf "\033[0;90m7d rst\033[0m \033[0;33m%dm\033[0m @%s" "$mins" "$reset_time")
    fi
  fi
else
  week_reset_part=$(printf "\033[0;90m7d rst --\033[0m")
fi

# --- time section ---
time_part=$(printf "\033[0;90m%s\033[0m" "$(date +%H:%M:%S)")

# --- assemble ---
SEP=$(printf " \033[0;90m|\033[0m ")
printf "%b%s%b%s%b%s%b%s%b%s%b%s%b%s%b" \
  "$git_part"        "$SEP" \
  "$model_part"      "$SEP" \
  "$five_part"       "$SEP" \
  "$reset_part"      "$SEP" \
  "$week_part"       "$SEP" \
  "$week_reset_part" "$SEP" \
  "$time_part"

