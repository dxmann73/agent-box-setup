#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
dev_parse_target 'Usage: sudo ./apply.sh --target daily-host|agent-vm' "$@"
dev_require_target daily-host agent-vm
[[ $EUID -eq 0 ]] || { echo 'Run with sudo.' >&2; exit 1; }
curl -fsSL https://tailscale.com/install.sh | sh
systemctl enable --now tailscaled
