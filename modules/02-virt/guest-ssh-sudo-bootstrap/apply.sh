#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

trap 'printf "ERROR: guest-ssh-sudo-bootstrap apply failed at line %s\n" "$LINENO" >&2' ERR

authorized_keys_source=
module_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp_authorized_keys=

usage() {
    cat <<'USAGE'
Usage: ./apply.sh --authorized-keys FILE

Run inside the Kubuntu guest console as the target guest user.

Options:
  --authorized-keys FILE  File containing approved authorized_keys lines. Use - for stdin.
  -h, --help              Show this help
USAGE
}

die() {
    printf '%s\n' "$@" >&2
    exit 1
}

cleanup() {
    if [[ -n "$tmp_authorized_keys" ]]; then
        rm -f "$tmp_authorized_keys"
    fi
}

trap cleanup EXIT

while [[ $# -gt 0 ]]; do
    case "$1" in
        --authorized-keys)
            [[ $# -ge 2 ]] || die '--authorized-keys requires a file path.'
            authorized_keys_source="$2"
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
    shift
done

[[ -n "$authorized_keys_source" ]] || {
    usage >&2
    exit 2
}

[[ $EUID -ne 0 ]] || die 'Run as the target guest user, not as root.'

if ! systemd-detect-virt --vm --quiet; then
    die 'This module applies inside a guest VM only.'
fi

for binary in awk grep install mktemp sudo systemctl visudo; do
    command -v "$binary" >/dev/null 2>&1 || die "Missing required command: ${binary}"
done

tmp_authorized_keys="$(mktemp)"
if [[ "$authorized_keys_source" == - ]]; then
    cat >"$tmp_authorized_keys"
else
    [[ -r "$authorized_keys_source" ]] || die "Cannot read authorized keys: ${authorized_keys_source}"
    cp "$authorized_keys_source" "$tmp_authorized_keys"
fi

grep -Eq \
    '(^|[[:space:]])(ssh-ed25519|ssh-rsa|ecdsa-sha2-nistp[0-9]+|sk-ssh-ed25519@openssh.com|sk-ecdsa-sha2-nistp256@openssh.com)[[:space:]]+[A-Za-z0-9+/]+=*' \
    "$tmp_authorized_keys" ||
    die 'Authorized keys file does not contain recognized public key material.'

if grep -Eq 'BEGIN (OPENSSH|RSA|DSA|EC|PRIVATE) KEY' "$tmp_authorized_keys"; then
    die 'Authorized keys input appears to contain a private key. Refusing to install it.'
fi

sudo -v
sudo env DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 update
sudo env DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 install -y \
    openssh-server

install -d -m 0700 "$HOME/.ssh"
install -m 0600 "$tmp_authorized_keys" "$HOME/.ssh/authorized_keys"

sudo install -d -m 0755 /etc/sudoers.d
sudo install -m 0440 /dev/null /etc/sudoers.d/agent-nopasswd
printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$USER" |
    sudo tee /etc/sudoers.d/agent-nopasswd >/dev/null
sudo chmod 0440 /etc/sudoers.d/agent-nopasswd
sudo visudo -cf /etc/sudoers.d/agent-nopasswd >/dev/null

sudo install -d -m 0755 /etc/ssh/sshd_config.d
sudo install -m 0644 "$module_dir/90-key-only.conf" /etc/ssh/sshd_config.d/90-key-only.conf
sudo sshd -t
sudo systemctl enable --now ssh
sudo systemctl reload ssh

printf 'guest SSH and passwordless sudo bootstrap applied for user: %s\n' "$USER"
