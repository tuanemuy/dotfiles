#!/usr/bin/env bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // ""')
effort=$(echo "$input" | jq -r '.effort.level // empty')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
five_pct=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')

# Build a progress bar: $1=percentage(0-100), $2=width
# Uses Braille chars for sub-character vertical fill precision (4 levels per cell)
make_bar() {
  local pct=$1
  local width=${2:-10}
  local total=$(( width * 4 ))
  local filled=$(awk "BEGIN { printf \"%d\", ($pct * $total / 100 + 0.5) }")
  [ "$filled" -gt "$total" ] && filled=$total
  local full_chars=$(( filled / 4 ))
  local partial=$(( filled % 4 ))
  local has_partial=$(( partial > 0 ? 1 : 0 ))
  local empty_chars=$(( width - full_chars - has_partial ))
  local bar=""
  for (( i=0; i<full_chars; i++ )); do bar="${bar}⣿"; done
  case $partial in
    1) bar="${bar}⣀" ;;
    2) bar="${bar}⣤" ;;
    3) bar="${bar}⣶" ;;
  esac
  for (( i=0; i<empty_chars; i++ )); do bar="${bar}⣀"; done
  printf '%s' "$bar"
}

# Color for percentage: green→yellow→red
pct_color() {
  local pct=$1
  if [ "$pct" -ge 90 ]; then
    printf '\033[31m'   # red
  elif [ "$pct" -ge 70 ]; then
    printf '\033[33m'   # yellow
  else
    printf '\033[32m'   # green
  fi
}

# Time remaining until a rate limit resets: $1=reset epoch (Unix seconds)
# Outputs a compact countdown like "2h13m", "3d4h", or "5m"
fmt_reset() {
  local epoch=$1
  local now diff d h m
  now=$(date +%s)
  diff=$(( epoch - now ))
  [ "$diff" -lt 0 ] && diff=0
  d=$(( diff / 86400 ))
  h=$(( (diff % 86400) / 3600 ))
  m=$(( (diff % 3600) / 60 ))
  if [ "$d" -gt 0 ]; then
    printf '%dd%dh' "$d" "$h"
  elif [ "$h" -gt 0 ]; then
    printf '%dh%dm' "$h" "$m"
  else
    printf '%dm' "$m"
  fi
}

# gruvbox accent colors for the effort level, matching the active terminal theme
# (palette values mirror starship's gruvbox-dark / gruvbox-light definitions)
if [ "${CURRENT_THEME:-light}" = "dark" ]; then
  gb_aqua='142;192;124'; gb_green='184;187;38'; gb_orange='254;128;25'; gb_red='251;73;52'
else
  gb_aqua='66;123;88'; gb_green='121;116;14'; gb_orange='175;58;3'; gb_red='157;0;6'
fi

# Truecolor escape for a reasoning effort level (falls back to dim for unknowns)
effort_color() {
  case "$1" in
    low)       printf '\033[38;2;%sm' "$gb_aqua" ;;
    medium)    printf '\033[38;2;%sm' "$gb_green" ;;
    high)      printf '\033[38;2;%sm' "$gb_orange" ;;
    xhigh|max) printf '\033[38;2;%sm' "$gb_red" ;;
    *)         printf '\033[2m' ;;
  esac
}

line1=""

# Context usage bar
if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")
  bar=$(make_bar "$used_int" 10)
  color=$(pct_color "$used_int")
  line1="${line1}$(printf "${color}ctx [%s] %d%%\033[0m" "$bar" "$used_int")"
fi

# 5h rate limit bar
if [ -n "$five_pct" ]; then
  five_int=$(printf '%.0f' "$five_pct")
  bar=$(make_bar "$five_int" 8)
  color=$(pct_color "$five_int")
  [ -n "$line1" ] && line1="${line1}  "
  line1="${line1}$(printf "${color}5h [%s] %d%%\033[0m" "$bar" "$five_int")"
  if [ -n "$five_reset" ]; then
    line1="${line1}$(printf "\033[2m (%s)\033[0m" "$(fmt_reset "$five_reset")")"
  fi
fi

# 7-day rate limit bar
if [ -n "$week_pct" ]; then
  week_int=$(printf '%.0f' "$week_pct")
  bar=$(make_bar "$week_int" 8)
  color=$(pct_color "$week_int")
  [ -n "$line1" ] && line1="${line1}  "
  line1="${line1}$(printf "${color}7d [%s] %d%%\033[0m" "$bar" "$week_int")"
  if [ -n "$week_reset" ]; then
    line1="${line1}$(printf "\033[2m (%s)\033[0m" "$(fmt_reset "$week_reset")")"
  fi
fi

# --- Line 2: model + git file changes ---
line2=""

# Model name (+ reasoning effort level if available)
if [ -n "$model" ]; then
  line2="$(printf '\033[35m%s\033[0m' "$model")"
  if [ -n "$effort" ]; then
    line2="${line2}$(printf ' %s%s\033[0m' "$(effort_color "$effort")" "$effort")"
  fi
fi

# Git file change summary (staged + unstaged counts)
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir >/dev/null 2>&1; then
  git_status=$(git -C "$cwd" status --porcelain 2>/dev/null)
  if [ -n "$git_status" ]; then
    staged=$(echo "$git_status" | grep -c '^[MADRC]' || true)
    unstaged=$(echo "$git_status" | grep -c '^.[MD]' || true)
    untracked=$(echo "$git_status" | grep -c '^??' || true)
    git_parts=""
    [ "$staged" -gt 0 ]   && git_parts="${git_parts}+${staged}"
    [ "$unstaged" -gt 0 ] && { [ -n "$git_parts" ] && git_parts="${git_parts} "; git_parts="${git_parts}~${unstaged}"; }
    [ "$untracked" -gt 0 ] && { [ -n "$git_parts" ] && git_parts="${git_parts} "; git_parts="${git_parts}?${untracked}"; }
    if [ -n "$git_parts" ]; then
      [ -n "$line2" ] && line2="${line2}  "
      line2="${line2}$(printf '\033[33m%s\033[0m' "$git_parts")"
    fi
  fi
fi

# Output: skip empty lines
if [ -n "$line1" ] && [ -n "$line2" ]; then
  printf '%s\n%s' "$line1" "$line2"
elif [ -n "$line1" ]; then
  printf '%s' "$line1"
elif [ -n "$line2" ]; then
  printf '%s' "$line2"
fi
