#!/usr/bin/env bash
set -Eeuo pipefail

check_shell=0
remote_host=""
failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh [--check-shell] [--remote HOST]

Options:
  --check-shell    Also check the current shell's SSH_AUTH_SOCK and SSH_ASKPASS
  --remote HOST    Prove a public-key login against HOST with ssh -v
  -h, --help       Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --check-shell)
            check_shell=1
            shift
            ;;
        --remote)
            remote_host="${2:-}"
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

[[ -n "${XDG_RUNTIME_DIR:-}" && -d "$XDG_RUNTIME_DIR" ]] || {
    printf '%s\n' 'XDG_RUNTIME_DIR is not set. Run this from a logged-in desktop session.' >&2
    exit 1
}

agent_socket_path="$XDG_RUNTIME_DIR/openssh_agent"
ssh_dir="$HOME/.ssh"
ssh_config="$ssh_dir/config"
gpg_agent_config="$HOME/.gnupg/gpg-agent.conf"
readonly agent_socket_path ssh_dir ssh_config gpg_agent_config

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

command_available() {
    command -v "$1" >/dev/null 2>&1
}

unit_masked() {
    [[ "$(systemctl --user is-enabled "$1" 2>/dev/null)" == masked ]]
}

mode_is() {
    local -r path="$1"
    local -r expected="$2"

    [[ -e "$path" ]] && [[ "$(stat -c '%a' "$path")" == "$expected" ]]
}

private_key_modes_ok() {
    local found

    found="$(find "$ssh_dir" -maxdepth 1 -type f \
        \( -name 'id_*' -o -name '*.pem' \) ! -name '*.pub' ! -perm 600 -print -quit)"
    [[ -z "$found" ]]
}

public_key_modes_ok() {
    local found

    found="$(find "$ssh_dir" -maxdepth 1 -type f -name '*.pub' ! -perm 644 -print -quit)"
    [[ -z "$found" ]]
}

ssh_config_adds_keys_to_agent() {
    grep -Eq '^[[:space:]]*AddKeysToAgent[[:space:]]+yes' "$ssh_config"
}

manager_environment_is() {
    local -r name="$1"
    local -r expected="$2"

    systemctl --user show-environment | grep -qxF "$name=$expected"
}

manager_environment_matches() {
    local -r name="$1"
    local -r pattern="$2"

    systemctl --user show-environment | grep -Eq "^$name=$pattern$"
}

agent_socket_answers() {
    SSH_AUTH_SOCK="$agent_socket_path" ssh-add -l >/dev/null 2>&1
    local -r status=$?

    # 0: keys listed, 1: agent reachable and empty, 2: cannot reach the agent
    ((status == 0 || status == 1))
}

gpg_ssh_support_unset() {
    [[ ! -f "$gpg_agent_config" ]] ||
        ! grep -Eq '^[[:space:]]*enable-ssh-support' "$gpg_agent_config"
}

shell_auth_sock_is_agent() {
    [[ "${SSH_AUTH_SOCK:-}" == "$agent_socket_path" ]]
}

shell_askpass_is_ksshaskpass() {
    [[ "${SSH_ASKPASS:-}" == *ksshaskpass ]]
}

remote_uses_publickey() {
    ssh -v -o BatchMode=yes -o PasswordAuthentication=no \
        -o KbdInteractiveAuthentication=no "$remote_host" true 2>&1 |
        grep -Eq 'Authenticated .*using "publickey"'
}

check 'running as normal user' normal_user

for command_name in ssh ssh-add ksshaskpass; do
    check "command available: $command_name" command_available "$command_name"
done

check 'gcr-ssh-agent.socket masked' unit_masked gcr-ssh-agent.socket
check 'gcr-ssh-agent.service masked' unit_masked gcr-ssh-agent.service
check 'ssh-agent.socket active' systemctl --user is-active --quiet ssh-agent.socket
check 'OpenSSH agent answers on the expected socket' agent_socket_answers
check 'systemd user SSH_AUTH_SOCK points at the OpenSSH agent' \
    manager_environment_is SSH_AUTH_SOCK "$agent_socket_path"
check 'systemd user SSH_ASKPASS is ksshaskpass' \
    manager_environment_matches SSH_ASKPASS '.*ksshaskpass'
check 'systemd user session prefers the askpass dialog' \
    manager_environment_matches SSH_ASKPASS_REQUIRE '(prefer|force)'

check '~/.ssh directory mode is 700' mode_is "$ssh_dir" 700
check '~/.ssh/config mode is 600' mode_is "$ssh_config" 600
check '~/.ssh/config sets AddKeysToAgent yes' ssh_config_adds_keys_to_agent
check 'private key modes are 600' private_key_modes_ok
check 'public key modes are 644' public_key_modes_ok

check 'gpg-agent does not claim the SSH socket' gpg_ssh_support_unset

if [[ $check_shell -eq 1 ]]; then
    check 'current shell SSH_AUTH_SOCK points at the OpenSSH agent' shell_auth_sock_is_agent
    check 'current shell SSH_ASKPASS is ksshaskpass' shell_askpass_is_ksshaskpass
fi

if [[ -n "$remote_host" ]]; then
    check "public-key login works against $remote_host" remote_uses_publickey
fi

if ((failures > 0)); then
    printf 'ssh-client verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'ssh-client verify passed'
