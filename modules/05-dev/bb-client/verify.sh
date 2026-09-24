#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
[[ $# -eq 4 && $1 == --target && $2 == daily-host && $3 == --url && $4 == https://* ]] || { echo "Usage: ./verify.sh --target daily-host --url 'https://private-bb-origin'" >&2; exit 2; }
dev_require_user
command -v tailscale >/dev/null
systemctl is-active --quiet tailscaled
curl --fail --silent --show-error --head --max-time 15 "$4" >/dev/null
echo 'bb-client verify passed; confirm execution-machine selection in the BB UI.'
