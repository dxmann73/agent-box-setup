#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "ERROR: ufw-firewall apply failed at line %s\n" "$LINENO" >&2' ERR

from_console=0

usage() {
    cat <<'USAGE'
Usage: ./apply.sh [--from-console]

Installs ufw and enables the default deny-in / allow-out baseline. Adds no per-service rules.

Options:
  --from-console   Acknowledge SSH-lockout risk. Required if UFW is currently inactive and the
                   invoking shell is over SSH.
  -h, --help       Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --from-console)
            from_console=1
            shift
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

[[ $EUID -ne 0 ]] || {
    printf '%s\n' 'Run as the normal user; the script uses sudo where needed.' >&2
    exit 1
}

sudo -n true 2>/dev/null || {
    printf '%s\n' \
        'sudo credentials are not cached.' \
        'Start the host-sudo-session babysit terminal or run sudo -v, then retry.' >&2
    exit 1
}

sudo apt-get install -y ufw

ufw_currently_active=0
if sudo ufw status | head -n 1 | grep -Fq 'Status: active'; then
    ufw_currently_active=1
fi

if ((ufw_currently_active == 0)) && [[ -n "${SSH_CONNECTION:-}" ]] && ((from_console == 0)); then
    printf '%s\n' \
        'UFW is inactive and this shell is over SSH.' \
        'Enabling with default deny incoming would drop the SSH session unless an allow rule is in place.' \
        'Add the allow rule for the SSH source from its owning module, prove a second fresh session works,' \
        'then rerun with --from-console.' >&2
    exit 1
fi

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw --force enable

sudo ufw status verbose

printf '%s\n' 'ufw-firewall applied. Default deny incoming, allow outgoing, enabled.'
