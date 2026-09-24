#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
dev_parse_target 'Usage: ./apply.sh --target daily-host|agent-vm' "$@"
dev_require_target daily-host agent-vm
dev_require_user
[[ $(npm prefix -g) == "$HOME"/* ]] || { echo 'Apply node-24 first.' >&2; exit 1; }
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
