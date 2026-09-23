#!/usr/bin/env bash
set -Eeuo pipefail
trap 'printf "ERROR: docker apply failed at line %s\n" "$LINENO" >&2' ERR
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

usage() { printf '%s\n' 'Usage: sudo ./apply.sh --target agent-vm'; }
if tool_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
tool_handle_parse_result "$status" usage || exit "$?"
tool_require_agent_vm || { usage >&2; exit 2; }
tool_require_sudo_user
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y docker.io
usermod -aG docker "$SUDO_USER"
systemctl enable --now docker.service
printf '%s\n' 'docker applied for agent-vm.' "Log out and back in before using Docker as $SUDO_USER without sudo."
