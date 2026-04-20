#!/usr/bin/env bash
# Status line: two-line layout with live context bar and cached ccusage data
input=$(cat)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')

# ANSI colors (actual escape chars via $'...' quoting)
C_RESET=$'\033[00m'
C_GREEN=$'\033[01;32m'
C_BLUE=$'\033[01;34m'
C_YELLOW=$'\033[33m'
C_RED_BOLD=$'\033[01;31m'
C_CTX_GREEN=$'\033[32m'
C_CTX_YELLOW=$'\033[33m'
C_CTX_RED=$'\033[31m'

# caveman
caveman_text=""
caveman_flag="$HOME/.claude/.caveman-active"
if [ -f "$caveman_flag" ]; then
  caveman_mode=$(cat "$caveman_flag" 2>/dev/null)
  if [ "$caveman_mode" = "full" ] || [ -z "$caveman_mode" ]; then
    caveman_text=$'\033[38;5;172m[CAVEMAN]\033[0m'
  else
    caveman_suffix=$(echo "$caveman_mode" | tr '[:lower:]' '[:upper:]')
    caveman_text=$'\033[38;5;172m[CAVEMAN:'"${caveman_suffix}"$']\033[0m'
  fi
fi

# Git branch
git_branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
  branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null \
    || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
  [ -n "$branch" ] && git_branch=" ($branch)"
fi

# Line 1: user@host:/path (branch)
line1="${C_GREEN}$(whoami)@$(hostname -s)${C_RESET}:${C_BLUE}${cwd}${C_YELLOW}${git_branch}${C_RESET}${caveman_text}"

# Context window (live from JSON)
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
ctx_tokens=$(echo "$input" | jq -r '
  .context_window.current_usage as $u |
  if $u then
    (($u.input_tokens // 0) + ($u.cache_creation_input_tokens // 0) + ($u.cache_read_input_tokens // 0))
  else empty end')
ctx_max=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

ctx_bar_str=""
ctx_label=""
if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct" 2>/dev/null || echo "0")

  if [ "$used_int" -lt 50 ]; then
    bar_color="$C_CTX_GREEN"
  elif [ "$used_int" -lt 80 ]; then
    bar_color="$C_CTX_YELLOW"
  else
    bar_color="$C_CTX_RED"
  fi

  filled=$(( used_int * 10 / 100 ))
  empty=$(( 10 - filled ))
  bar=""
  for ((i=0; i<filled; i++)); do bar="${bar}▓"; done
  for ((i=0; i<empty; i++)); do bar="${bar}░"; done

  ctx_bar_str="${bar_color}${bar}${C_RESET}"

  # Format token count: show as Xk/Xk, turn red bold at >= 150k
  tok_str=""
  if [ -n "$ctx_tokens" ]; then
    tok_k=$(( ctx_tokens / 1000 ))
    if [ -n "$ctx_max" ]; then
      max_k=$(( ctx_max / 1000 ))
      tok_str="${tok_k}k/${max_k}k"
    else
      tok_str="${tok_k}k"
    fi
    if [ "$ctx_tokens" -ge 150000 ]; then
      tok_str="${C_RED_BOLD}${tok_str}${C_RESET}"
    fi
  fi

  ctx_label=" ${used_int}%"
  [ -n "$tok_str" ] && ctx_label="${ctx_label} (${tok_str})"
fi

# ccusage caching: bucket to nearest 10 seconds
CACHE_FILE="/tmp/claude-ccusage-output"
TMP_CACHE="/tmp/claude-ccusage-output.tmp"
BUCKET_FILE="/tmp/claude-ccusage-bucket"

now_sec=$(date +%s)
current_bucket=$(( (now_sec / 10) * 10 ))

stored_bucket=""
[ -f "$BUCKET_FILE" ] && stored_bucket=$(cat "$BUCKET_FILE" 2>/dev/null)

if [ "$current_bucket" != "$stored_bucket" ]; then
  echo "$current_bucket" > "$BUCKET_FILE"
  # Run ccusage in background, atomically update cache on success
  (echo "$input" | npx ccusage@latest statusline --offline > "$TMP_CACHE" 2>/dev/null \
    && mv "$TMP_CACHE" "$CACHE_FILE") &
fi

# Parse ccusage cache output
ccusage_model=""
ccusage_cost=""
if [ -f "$CACHE_FILE" ]; then
  # Strip ANSI codes, find the statusline output line
  ccusage_raw=$(sed 's/\x1b\[[0-9;]*m//g' "$CACHE_FILE" 2>/dev/null | grep -m1 '🤖')
  if [ -n "$ccusage_raw" ]; then
    ccusage_model=$(echo "$ccusage_raw" | sed 's/.*🤖 \([^|]*\)|.*/\1/' | sed 's/[[:space:]]*$//')
    ccusage_cost=$(echo "$ccusage_raw" | sed 's/.*💰 \([^|]*\)|.*/\1/' | sed 's/[[:space:]]*$//')
  fi
fi

# Weekly spending limit (7-day rate limit from JSON)
weekly_str=""
week_pct=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
week_resets_at=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')
if [ -n "$week_pct" ]; then
  week_int=$(printf '%.0f' "$week_pct" 2>/dev/null || echo "0")

  reset_label=""
  if [ -n "$week_resets_at" ]; then
    now_epoch=$(date +%s)
    days_left=$(( (week_resets_at - now_epoch + 86399) / 86400 ))
    reset_date=$(date -d "@${week_resets_at}" '+%a %b %-d %H:%M' 2>/dev/null \
      || date -r "$week_resets_at" '+%a %b %-d %H:%M' 2>/dev/null)
    reset_label="resets in ${days_left}d (${reset_date})"
  fi

  if [ "$week_int" -ge 80 ]; then
    weekly_str=" ${C_RED_BOLD}/ used ${week_int}%${reset_label:+, $reset_label}${C_RESET}"
  elif [ "$week_int" -ge 50 ]; then
    weekly_str=" ${C_CTX_YELLOW}/ used ${week_int}%${reset_label:+, $reset_label}${C_RESET}"
  else
    weekly_str=" / used ${week_int}%${reset_label:+, $reset_label}"
  fi
fi

# Rate limit reset: written by post-tool hook when rate limit fires
rate_reset_str=""
if [ -f /tmp/claude-rate-reset ]; then
  reset_epoch=$(cat /tmp/claude-rate-reset 2>/dev/null)
  now=$(date +%s)
  if [ -n "$reset_epoch" ] && [ "$reset_epoch" -gt "$now" ]; then
    secs=$(( reset_epoch - now ))
    mins=$(( secs / 60 ))
    secs=$(( secs % 60 ))
    rate_reset_str=" ${C_RED_BOLD}[RL reset ${mins}m${secs}s]${C_RESET}"
  else
    rm -f /tmp/claude-rate-reset
  fi
fi

# Line 2: [Model] ▓▓▓░░░░░░░ 32% | $x.xx session / $x.xx today / block (Xh Xm left)
model_part=""
[ -n "$ccusage_model" ] && model_part="[${ccusage_model}] "

cost_part=""
[ -n "$ccusage_cost" ] && cost_part=" | ${ccusage_cost}"

line2="${model_part}${ctx_bar_str}${ctx_label}${cost_part}${weekly_str}${rate_reset_str}"

printf "%s\n%s\n" "$line1" "$line2"
