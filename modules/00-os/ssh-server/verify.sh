#!/usr/bin/env bash
set -Eeuo pipefail

require_active=0
failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh [--require-active]

Options:
  --require-active   Also require the sshd unit to be active
  -h, --help         Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --require-active)
            require_active=1
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

sudo -n true 2>/dev/null || {
    printf '%s\n' \
        'sudo credentials are not cached; sshd -T needs root.' \
        'Start the host-sudo-session babysit terminal or run sudo -v, then retry.' >&2
    exit 1
}

drop_in_path='/etc/ssh/sshd_config.d/10-key-only.conf'
readonly drop_in_path

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

drop_in_present() {
    sudo test -f "$drop_in_path"
}

sshd_config_valid() {
    sudo sshd -t
}

effective_option_is() {
    local -r name="$1"
    local -r expected="$2"

    sudo sshd -T | grep -qx "$name $expected"
}

check 'openssh-server installed' command_available sshd
check 'key-only drop-in present' drop_in_present
check 'sshd configuration valid' sshd_config_valid
check 'requires public-key authentication' effective_option_is authenticationmethods publickey
check 'password authentication disabled' effective_option_is passwordauthentication no
check 'keyboard-interactive authentication disabled' \
    effective_option_is kbdinteractiveauthentication no
check 'root login disabled' effective_option_is permitrootlogin no
check 'empty passwords disabled' effective_option_is permitemptypasswords no
check 'pubkey authentication enabled' effective_option_is pubkeyauthentication yes

if [[ $require_active -eq 1 ]]; then
    check 'sshd active' systemctl is-active --quiet ssh
fi

if ((failures > 0)); then
    printf 'ssh-server verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'ssh-server verify passed'
