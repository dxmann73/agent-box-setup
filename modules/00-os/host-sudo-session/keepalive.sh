#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "ERROR: host-sudo-session keepalive failed at line %s\n" "$LINENO" >&2' ERR

interval=60

usage() {
    cat <<'USAGE'
Usage: ./keepalive.sh [--interval SECONDS]

Keeps the current user's sudo timestamp alive in this terminal. Stop with Ctrl-C.

Options:
  --interval VALUE   Refresh interval in seconds, default: 60
  -h, --help         Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --interval)
            interval="${2:-}"
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

[[ "$interval" =~ ^[0-9]+$ && "$interval" -gt 0 ]] || {
    printf 'Invalid --interval: %s\n' "$interval" >&2
    usage >&2
    exit 2
}

[[ $EUID -ne 0 ]] || {
    printf '%s\n' 'Run as the normal desktop user, not root.' >&2
    exit 1
}

printf '%s\n' 'Authenticating sudo for this terminal. Host sudo remains password-protected.'
sudo -v
printf 'sudo timestamp active. Refreshing every %s second(s); stop with Ctrl-C.\n' "$interval"

while true; do
    sleep "$interval"
    sudo -n -v
done
