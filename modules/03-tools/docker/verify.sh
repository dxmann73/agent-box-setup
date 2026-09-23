#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

usage() {
    cat <<'USAGE'
Usage: ./verify.sh --target agent-vm [--smoke]

Options:
  --smoke   Pull and run hello-world as the current user. Requires a new login
            after apply and network access to the container registry.
USAGE
}
if tool_parse_docker_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
tool_handle_parse_result "$status" usage || exit "$?"
tool_require_agent_vm || { usage >&2; exit 2; }
[[ $EUID -ne 0 ]] || { printf '%s\n' 'Run as the normal desktop user, not with sudo.' >&2; exit 1; }
user_in_docker_group() { id -nG "$USER" | tr ' ' '\n' | grep -qx docker; }
docker_daemon_answers() { docker version --format '{{.Server.Version}}' | grep -Eq '^[0-9]'; }
tool_check 'docker.io package installed' tool_package_installed docker.io
tool_check 'docker is on PATH' command -v docker
tool_check 'docker service enabled' systemctl is-enabled --quiet docker.service
tool_check 'docker service active' systemctl is-active --quiet docker.service
tool_check "${USER} has an active docker group membership" user_in_docker_group
tool_check 'Docker daemon answers without sudo' docker_daemon_answers
if ((tool_smoke == 1)); then
    tool_check 'hello-world container runs' docker run --rm hello-world
fi
tool_finish_verify docker
