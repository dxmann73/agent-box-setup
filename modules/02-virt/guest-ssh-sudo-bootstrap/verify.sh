#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh

Run inside the Kubuntu guest. Checks SSH key-only bootstrap and guest passwordless sudo.

Optional environment:
  GUEST_BOOTSTRAP_HOSTNAME   expected guest hostname
  AGENT_BOX_VM_HOSTNAME      fallback expected hostname for the agent VM
  GUEST_BOOTSTRAP_HOST_IPV4  host bridge IPv4 expected in an authorized_keys from= restriction

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

inside_guest() {
    systemd-detect-virt --vm --quiet
}

hostname_matches_when_expected() {
    local expected_hostname

    expected_hostname="${GUEST_BOOTSTRAP_HOSTNAME:-${AGENT_BOX_VM_HOSTNAME:-}}"
    [[ -z "$expected_hostname" ]] || [[ "$(hostname)" == "$expected_hostname" ]]
}

authorized_keys_permissions() {
    [[ -d "$HOME/.ssh" ]] || return 1
    [[ -f "$HOME/.ssh/authorized_keys" ]] || return 1
    [[ "$(stat -c '%a' "$HOME/.ssh")" == 700 ]] || return 1
    [[ "$(stat -c '%a' "$HOME/.ssh/authorized_keys")" == 600 ]]
}

authorized_keys_has_public_key() {
    grep -Eq \
        '(^|[[:space:]])(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp[0-9]+|sk-ssh-ed25519@openssh.com|sk-ecdsa-sha2-nistp256@openssh.com)[[:space:]]+[A-Za-z0-9+/]+=*' \
        "$HOME/.ssh/authorized_keys"
}

authorized_keys_has_no_private_key() {
    ! grep -Eq 'BEGIN (OPENSSH|RSA|DSA|EC|PRIVATE) KEY' "$HOME/.ssh/authorized_keys"
}

host_key_restricted_when_expected() {
    local key_line

    [[ -z "${GUEST_BOOTSTRAP_HOST_IPV4:-}" ]] && return 0

    key_line="$(
        grep -F "from=\"${GUEST_BOOTSTRAP_HOST_IPV4}\"" "$HOME/.ssh/authorized_keys" |
            head -n 1
    )"
    [[ -n "$key_line" ]] || return 1
    [[ "$key_line" == *no-agent-forwarding* ]] || return 1
    [[ "$key_line" == *no-X11-forwarding* ]]
}

sudo_non_interactive() {
    sudo -n true
}

sudoers_rule_exact() {
    local active_lines

    sudo -n test -f /etc/sudoers.d/agent-nopasswd || return 1
    [[ "$(sudo -n stat -c '%a' /etc/sudoers.d/agent-nopasswd)" == 440 ]] || return 1
    active_lines="$(sudo -n awk 'NF && $1 !~ /^#/' /etc/sudoers.d/agent-nopasswd)"
    [[ "$active_lines" == "$USER ALL=(ALL) NOPASSWD: ALL" ]]
}

sshd_effective_has() {
    sudo -n sshd -T | grep -qx "$1"
}

check 'inside a virtualized guest' inside_guest
check 'hostname matches expected value when set' hostname_matches_when_expected
check 'sudo available' command_available sudo
check 'sshd available' command_available sshd
check 'systemctl available' command_available systemctl
check 'stat available' command_available stat
check 'authorized_keys permissions are strict' authorized_keys_permissions
check 'authorized_keys contains public key material' authorized_keys_has_public_key
check 'authorized_keys does not contain a private key' authorized_keys_has_no_private_key
check 'host key restriction matches expected bridge IPv4 when set' \
    host_key_restricted_when_expected
check 'passwordless guest sudo works' sudo_non_interactive
check 'agent-nopasswd sudoers rule is exact' sudoers_rule_exact
check 'sshd active' systemctl is-active --quiet ssh
check 'sshd configuration valid' sudo -n sshd -t
check 'sshd requires public-key authentication' \
    sshd_effective_has 'authenticationmethods publickey'
check 'sshd password authentication disabled' sshd_effective_has 'passwordauthentication no'
check 'sshd keyboard-interactive authentication disabled' \
    sshd_effective_has 'kbdinteractiveauthentication no'
check 'sshd root login disabled' sshd_effective_has 'permitrootlogin no'
check 'sshd empty passwords disabled' sshd_effective_has 'permitemptypasswords no'

if ((failures > 0)); then
    printf '%s guest-ssh-sudo-bootstrap check(s) failed\n' "$failures" >&2
    exit 1
fi

printf 'guest-ssh-sudo-bootstrap verification passed\n'
