#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "ERROR: ssh-client apply failed at line %s\n" "$LINENO" >&2' ERR

usage() {
    cat <<'USAGE'
Usage: ./apply.sh

Configures the single OpenSSH agent, askpass, and ~/.ssh permissions for the current user.

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

[[ $EUID -ne 0 ]] || {
    printf '%s\n' 'Run as the normal desktop user, not with sudo.' >&2
    exit 1
}

[[ -n "${XDG_RUNTIME_DIR:-}" && -d "$XDG_RUNTIME_DIR" ]] || {
    printf '%s\n' 'XDG_RUNTIME_DIR is not set. Run this from a logged-in desktop session.' >&2
    exit 1
}

for command_name in ssh ssh-add ksshaskpass systemctl; do
    command -v "$command_name" >/dev/null 2>&1 || {
        printf 'Missing required command: %s\n' "$command_name" >&2
        exit 1
    }
done

agent_socket_path="$XDG_RUNTIME_DIR/openssh_agent"
ssh_dir="$HOME/.ssh"
ssh_config="$ssh_dir/config"
plasma_askpass_script="/etc/xdg/plasma-workspace/env/ksshaskpass.sh"
gpg_agent_config="$HOME/.gnupg/gpg-agent.conf"
readonly agent_socket_path ssh_dir ssh_config plasma_askpass_script gpg_agent_config

grep -q 'ksshaskpass' "$plasma_askpass_script" 2>/dev/null || {
    printf '%s\n' \
        "$plasma_askpass_script does not export ksshaskpass." \
        'The Plasma session must set SSH_ASKPASS. Reinstall plasma-workspace, then rerun.' >&2
    exit 1
}

if [[ -f "$gpg_agent_config" ]] &&
    grep -Eq '^[[:space:]]*enable-ssh-support' "$gpg_agent_config"; then
    printf '%s\n' \
        "enable-ssh-support is set in $gpg_agent_config." \
        'Remove that line so gpg-agent does not claim SSH_AUTH_SOCK, then rerun.' >&2
    exit 1
fi

systemctl --user cat ssh-agent.socket >/dev/null 2>&1 || {
    printf '%s\n' 'ssh-agent.socket user unit not found. Install openssh-client, then rerun.' >&2
    exit 1
}

install -d -m 0700 "$ssh_dir"
chmod 0700 "$ssh_dir"

while IFS= read -r -d '' key_path; do
    chmod 0600 "$key_path"
done < <(find "$ssh_dir" -maxdepth 1 -type f \
    \( -name 'id_*' -o -name '*.pem' -o -name 'authorized_keys' -o -name 'known_hosts' \) \
    ! -name '*.pub' -print0)

while IFS= read -r -d '' public_key_path; do
    chmod 0644 "$public_key_path"
done < <(find "$ssh_dir" -maxdepth 1 -type f -name '*.pub' -print0)

if [[ -e "$ssh_config" ]]; then
    chmod 0600 "$ssh_config"
else
    install -m 0600 /dev/null "$ssh_config"
fi

if ! grep -Eq '^[[:space:]]*AddKeysToAgent[[:space:]]+yes' "$ssh_config"; then
    if [[ -s "$ssh_config" ]]; then
        cp -a "$ssh_config" "$ssh_config.bak-$(date +%Y%m%d-%H%M%S)"
        printf '\n' >>"$ssh_config"
    fi
    cat >>"$ssh_config" <<'CONFIG'
Host *
    AddKeysToAgent yes
CONFIG
    chmod 0600 "$ssh_config"
fi

for unit in gcr-ssh-agent.socket gcr-ssh-agent.service; do
    if systemctl --user is-active --quiet "$unit"; then
        systemctl --user stop "$unit"
    fi
    systemctl --user mask "$unit"
done

systemctl --user enable --now ssh-agent.socket
systemctl --user set-environment SSH_AUTH_SOCK="$agent_socket_path"

printf '%s\n' \
    'ssh-client applied.' \
    "Agent socket: $agent_socket_path" \
    'Log out and back in so the session drops the gcr socket path and picks up ksshaskpass.'
