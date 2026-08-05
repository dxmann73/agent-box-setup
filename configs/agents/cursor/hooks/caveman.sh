#!/usr/bin/env bash
# Cursor sessionStart hook: inject always-on caveman mode.
# Contract: read session JSON on stdin, print {"additional_context": "..."} on stdout.
# Docs: https://cursor.com/docs/hooks#sessionstart
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
context_file="$script_dir/caveman.md"

cat >/dev/null # drain stdin payload, unused

if [ ! -r "$context_file" ]; then
    echo "caveman.sh: missing $context_file" >&2
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "caveman.sh: jq not found" >&2
    exit 1
fi

jq -n --rawfile ctx "$context_file" '{additional_context: $ctx}'
