#!/usr/bin/env bash
set -Eeuo pipefail

failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh

Checks that ufw is installed, active, and enforces the deny-in / allow-out baseline.

Options:
  -h, --help   Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
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

sudo -n true 2>/dev/null || {
    printf '%s\n' \
        'sudo credentials are not cached; ufw status needs root.' \
        'Start the host-sudo-session babysit terminal or run sudo -v, then retry.' >&2
    exit 1
}

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

command_available() {
    command -v "$1" >/dev/null 2>&1
}

status_line() {
    sudo ufw status verbose | grep -E "^$1:" | head -n 1
}

status_active() {
    sudo ufw status | head -n 1 | grep -Fq 'Status: active'
}

default_incoming_deny() {
    status_line 'Default' | grep -Fq 'deny (incoming)'
}

default_outgoing_allow() {
    status_line 'Default' | grep -Fq 'allow (outgoing)'
}

enabled_on_boot() {
    grep -Eq '^\s*ENABLED\s*=\s*yes\b' /etc/ufw/ufw.conf
}

check 'ufw installed' command_available ufw
check 'ufw active' status_active
check 'default policy: deny incoming' default_incoming_deny
check 'default policy: allow outgoing' default_outgoing_allow
check 'ufw enabled on boot' enabled_on_boot

if ((failures > 0)); then
    printf 'ufw-firewall verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'ufw-firewall verify passed'
