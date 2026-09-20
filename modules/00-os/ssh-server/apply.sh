#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "ERROR: ssh-server apply failed at line %s\n" "$LINENO" >&2' ERR

override_lockout=0

usage() {
    cat <<'USAGE'
Usage: ./apply.sh [--i-have-a-key]

Installs openssh-server and drops the key-only sshd configuration.

Options:
  --i-have-a-key   Reload a running sshd even if this user has no authorized_keys entry.
                   Use only when a different account on the same host owns the key material.
  -h, --help       Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --i-have-a-key)
            override_lockout=1
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

drop_in_path='/etc/ssh/sshd_config.d/10-key-only.conf'
legacy_drop_in_path='/etc/ssh/sshd_config.d/90-key-only.conf'
cloud_init_drop_in='/etc/ssh/sshd_config.d/50-cloud-init.conf'
system_info_dir="$HOME/system-info"
readonly drop_in_path legacy_drop_in_path cloud_init_drop_in system_info_dir

[[ -d "$system_info_dir" ]] || {
    printf '%s\n' \
        "$system_info_dir is missing." \
        'Run kubuntu-baseline first; it owns the ~/system-info directory.' >&2
    exit 1
}

sudo apt-get install -y openssh-server

if sudo test -f "$cloud_init_drop_in"; then
    if sudo grep -Eq '^[[:space:]]*(PasswordAuthentication|KbdInteractiveAuthentication|ChallengeResponseAuthentication)[[:space:]]' "$cloud_init_drop_in"; then
        printf '%s\n' \
            "$cloud_init_drop_in overrides an authentication keyword." \
            'sshd first-value-wins: cloud-init loads before our drop-in and would decide.' \
            'Remove those lines by hand (or delete the file if cloud-init is not managing this host), then rerun.' >&2
        exit 1
    fi
fi

sshd_snapshot="$system_info_dir/sshd-effective-before-hardening.txt"
fingerprints_snapshot="$system_info_dir/ssh-host-key-fingerprints.txt"
readonly sshd_snapshot fingerprints_snapshot

if [[ ! -e "$sshd_snapshot" ]]; then
    sudo sshd -T >"$sshd_snapshot"
fi
if [[ ! -e "$fingerprints_snapshot" ]]; then
    for host_key in /etc/ssh/ssh_host_*_key.pub; do
        [[ -e "$host_key" ]] && ssh-keygen -lf "$host_key"
    done >"$fingerprints_snapshot"
fi

desired_drop_in=$(cat <<'CONFIG'
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
AuthenticationMethods publickey
PermitRootLogin no
PermitEmptyPasswords no
CONFIG
)

drop_in_needs_write=1
if sudo test -f "$drop_in_path"; then
    if sudo cmp -s "$drop_in_path" <(printf '%s\n' "$desired_drop_in"); then
        drop_in_needs_write=0
    fi
fi

if ((drop_in_needs_write)); then
    tmp_drop_in="$(mktemp)"
    trap 'rm -f "$tmp_drop_in"' EXIT
    printf '%s\n' "$desired_drop_in" >"$tmp_drop_in"
    sudo install -o root -g root -m 0644 "$tmp_drop_in" "$drop_in_path"
fi

if sudo test -f "$legacy_drop_in_path"; then
    sudo rm -f "$legacy_drop_in_path"
fi

if ! sudo sshd -t; then
    printf '%s\n' 'sshd -t failed. Removing drop-in and leaving the running server untouched.' >&2
    sudo rm -f "$drop_in_path"
    exit 1
fi

effective_ok=1
declare -A required=(
    [pubkeyauthentication]=yes
    [passwordauthentication]=no
    [kbdinteractiveauthentication]=no
    [authenticationmethods]=publickey
    [permitrootlogin]=no
    [permitemptypasswords]=no
)
effective="$(sudo sshd -T)"
for keyword in "${!required[@]}"; do
    if ! grep -qx "$keyword ${required[$keyword]}" <<<"$effective"; then
        printf 'effective value for %s is not %s (got: %s)\n' \
            "$keyword" "${required[$keyword]}" "$(grep -E "^$keyword " <<<"$effective" || echo missing)" >&2
        effective_ok=0
    fi
done

if ((effective_ok == 0)); then
    printf '%s\n' \
        'sshd -T disagrees with the key-only drop-in.' \
        'Another drop-in or a Match block overrides these keywords.' \
        'Removing our drop-in and leaving the running server untouched.' >&2
    sudo rm -f "$drop_in_path"
    exit 1
fi

if systemctl is-active --quiet ssh; then
    if ((override_lockout == 0)); then
        authorized_keys="$HOME/.ssh/authorized_keys"
        if [[ ! -s "$authorized_keys" ]]; then
            printf '%s\n' \
                "$authorized_keys is missing or empty." \
                'Refusing to reload sshd with password auth off. Add a public key first,' \
                'or pass --i-have-a-key if another account on this host owns the key.' >&2
            exit 1
        fi
    fi
    sudo systemctl reload ssh
    printf '%s\n' 'ssh-server applied. sshd reloaded with key-only policy.'
else
    printf '%s\n' \
        'ssh-server applied. Drop-in installed; sshd is not running.' \
        'Prove a public-key login, then: sudo systemctl enable --now ssh'
fi
