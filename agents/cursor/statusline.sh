#!/usr/bin/env bash
# Cursor CLI status line: model, context window, and plan usage with reset date.
# Contract: read status line JSON on stdin, print one line on stdout.
#
# Context data comes from the stdin payload. Plan usage does not: Cursor only exposes it
# through the internal aiserver.v1.DashboardService/GetCurrentPeriodUsage RPC (the same
# call behind /usage). That API is undocumented and may change on any Cursor update, so it
# is fetched in the background, cached, and shown as "plan n/a" when the call fails.
set -euo pipefail

auth_file="${CURSOR_AUTH_FILE:-$HOME/.config/cursor/auth.json}"
api_url="${CURSOR_API_URL:-https://api2.cursor.sh}/aiserver.v1.DashboardService/GetCurrentPeriodUsage"
cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/cursor-statusline"
cache_file="$cache_dir/usage.json"
error_file="$cache_dir/usage.error"
lock_dir="$cache_dir/refresh.lock"
refresh_after_seconds=60

command -v jq >/dev/null 2>&1 || { echo "statusline.sh: jq not found" >&2; exit 1; }

refresh_usage() {
    trap 'rmdir "$lock_dir" 2>/dev/null || true' EXIT
    local token response tmp
    if ! token=$(jq -er '.accessToken' "$auth_file" 2>/dev/null); then
        echo "no accessToken in $auth_file" > "$error_file"
        return 1
    fi
    # Header goes through stdin so the token never appears in the process list.
    if ! response=$(printf 'Authorization: Bearer %s\n' "$token" | curl -sS --fail -m 10 \
        -X POST "$api_url" -H @- \
        -H 'Content-Type: application/json' -H 'Connect-Protocol-Version: 1' \
        -d '{}' 2>&1); then
        echo "request failed: $response" > "$error_file"
        return 1
    fi
    if ! jq -e '(.billingCycleEnd | tonumber) > 0
                and (.planUsage.limit | type == "number" and . > 0)
                and (.planUsage.includedSpend | type == "number")' <<<"$response" >/dev/null 2>&1; then
        echo "unexpected response shape: ${response:0:300}" > "$error_file"
        return 1
    fi
    tmp=$(mktemp "$cache_dir/usage.XXXXXX")
    printf '%s\n' "$response" > "$tmp"
    mv "$tmp" "$cache_file"
    rm -f "$error_file"
}

if [ "${1:-}" = "--refresh" ]; then
    refresh_usage
    exit
fi

payload=$(cat)
jq -e 'type == "object"' <<<"$payload" >/dev/null 2>&1 \
    || { echo "statusline.sh: stdin is not a JSON object" >&2; exit 1; }

mkdir -p "$cache_dir"
now=$(date +%s)
cache_mtime=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
error_mtime=$(stat -c %Y "$error_file" 2>/dev/null || echo 0)
last_attempt=$(( cache_mtime > error_mtime ? cache_mtime : error_mtime ))
lock_mtime=$(stat -c %Y "$lock_dir" 2>/dev/null || echo "$now")
if (( now - lock_mtime > 30 )); then
    rmdir "$lock_dir" 2>/dev/null || true # refresh died without cleanup
fi
if (( now - last_attempt >= refresh_after_seconds )) && mkdir "$lock_dir" 2>/dev/null; then
    setsid -f "${BASH_SOURCE[0]}" --refresh </dev/null >/dev/null 2>&1
fi

# Error newer than cache: show n/a rather than a stale number.
usage='null'
if [ -f "$cache_file" ] && (( cache_mtime >= error_mtime )); then
    usage=$(cat "$cache_file")
fi

jq -rn --argjson p "$payload" --argjson u "$usage" '
    def tokens: if . == null then "?" elif . >= 1000000 then "\(. / 1000000 | floor)M"
                elif . >= 1000 then "\(. / 1000 | floor)k" else tostring end;
    def pct: "\(. * 10 | round / 10)%";
    [
        ($p.model.display_name // $p.model.id // "unknown"),
        ($p.context_window as $c
            | if $c.used_percentage == null then "ctx \($c.context_window_size | tokens)"
              else "ctx \($c.used_percentage | pct) of \($c.context_window_size | tokens)" end),
        (if $u == null then "plan n/a"
         else ($u.planUsage as $pu
            | "plan \($pu.includedSpend / $pu.limit * 100 | round)% ($\($pu.includedSpend / 100)/$\($pu.limit / 100))"
            + " · resets \($u.billingCycleEnd | tonumber / 1000 | strftime("%b %-d"))")
         end)
    ] | join(" · ")'
