#!/usr/bin/env bash
# Apply the repository-managed subset of Cursor CLI settings to ~/.cursor/cli-config.json.
#
# Cursor owns that file at runtime: it rewrites the selected model, model parameters,
# privacy cache and authInfo on every session. Symlinking it would push live state and a
# real auth id into git, so this script merges only the keys the repository declares and
# leaves everything else untouched.
#
# Permission-bearing keys (permissions, approvalMode, sandbox) are applied by default.
set -euo pipefail

repo_config="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/cli-config.json"
live_config="${CURSOR_CLI_CONFIG:-$HOME/.cursor/cli-config.json}"

apply_permissions=true
for arg in "$@"; do
    case "$arg" in
        --permissions) apply_permissions=true ;;
        --no-permissions) apply_permissions=false ;;
        *) echo "unknown argument: $arg" >&2; exit 2 ;;
    esac
done

command -v jq > /dev/null || { echo "jq is required" >&2; exit 1; }
[ -f "$repo_config" ] || { echo "missing template: $repo_config" >&2; exit 1; }
if [ ! -f "$live_config" ]; then
    # A fresh credential-free guest must be configurable before first launch.
    # Cursor will add its own auth state later; the merge below preserves it.
    install -d -m 0700 "$(dirname "$live_config")"
    printf '{}\n' > "$live_config"
    chmod 0600 "$live_config"
fi
jq -e . "$repo_config" > /dev/null || { echo "template is not valid JSON: $repo_config" >&2; exit 1; }
jq -e . "$live_config" > /dev/null || { echo "live config is not valid JSON: $live_config" >&2; exit 1; }

# Replaced wholesale, not deep-merged: dropping a key from the template must also drop it
# from the live file, otherwise stale settings such as display.mode=zen survive forever.
managed_keys=(display editor network attribution statusLine)
if [ "$apply_permissions" = true ]; then
    managed_keys+=(permissions approvalMode sandbox)
fi

for key in "${managed_keys[@]}"; do
    jq -e --arg key "$key" 'has($key)' "$repo_config" > /dev/null \
        || { echo "template has no '$key' key: $repo_config" >&2; exit 1; }
done

backup="$live_config.bak"
cp "$live_config" "$backup"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
jq --slurpfile template "$repo_config" \
   'reduce $ARGS.positional[] as $key (.; .[$key] = $template[0][$key])' \
   "$live_config" --args "${managed_keys[@]}" > "$tmp"
jq -e . "$tmp" > /dev/null || { echo "merge produced invalid JSON; $live_config left unchanged" >&2; exit 1; }
mv "$tmp" "$live_config"
trap - EXIT

echo "applied [${managed_keys[*]}] from $repo_config"
echo "previous config saved to $backup"
if [ "$apply_permissions" = false ]; then
    echo "permissions/approvalMode/sandbox left as-is (--no-permissions)"
fi
