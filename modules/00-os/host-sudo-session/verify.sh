#!/usr/bin/env bash
set -Eeuo pipefail

require_active=0
terminal_id=""
failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh [--require-active] [--terminal-id TERM_ID]

Options:
  --require-active   Require an already-authenticated sudo timestamp
  --terminal-id ID    Verify a running BB sudo babysit terminal by terminal id
  -h, --help         Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --require-active)
            require_active=1
            shift
            ;;
        --terminal-id)
            terminal_id="${2:-}"
            shift 2
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown argument: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

check() {
    local -r label="$1"
    shift

    if "$@"; then
        printf 'ok - %s\n' "$label"
    else
        printf 'not ok - %s\n' "$label" >&2
        failures=$((failures + 1))
    fi
}

normal_user() {
    [[ $EUID -ne 0 ]]
}

agent_nopasswd_absent() {
    [[ ! -e /etc/sudoers.d/agent-nopasswd ]]
}

sudo_timestamp_active() {
    sudo -n -v
}

bb_terminal_running() {
    bb terminal show "$terminal_id" | grep -Eq '"status":[[:space:]]*"running"|^Status: running$'
}

bb_terminal_authenticated() {
    bb terminal output "$terminal_id" --tail-bytes 4096 |
        grep -Fq 'sudo timestamp active. Refreshing every'
}

check 'running as normal user' normal_user
check 'host has no agent NOPASSWD sudoers file' agent_nopasswd_absent

if [[ $require_active -eq 1 ]]; then
    check 'sudo timestamp is active' sudo_timestamp_active
fi

if [[ -n "$terminal_id" ]]; then
    check 'BB sudo babysit terminal is running' bb_terminal_running
    check 'BB sudo babysit terminal authenticated sudo' bb_terminal_authenticated
fi

if ((failures > 0)); then
    printf 'host-sudo-session verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'host-sudo-session verify passed'
