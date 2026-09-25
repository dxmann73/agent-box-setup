#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

trap 'printf "ERROR: guest-ssh-sudo-bootstrap apply failed at line %s\n" "$LINENO" >&2' ERR

authorized_keys_source=
module_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp_authorized_keys=
host_bridge_ipv4="${GUEST_BOOTSTRAP_HOST_IPV4:-}"

usage() {
    cat <<'USAGE'
Usage: ./apply.sh --authorized-keys FILE

Run inside the Kubuntu guest console as the target guest user.

Options:
  --authorized-keys FILE  File containing approved authorized_keys lines. Use - for stdin.

Optional environment:
  GUEST_BOOTSTRAP_HOST_IPV4  Exact host bridge IPv4 allowed to SSH through UFW.
  -h, --help              Show this help
USAGE
}

die() {
    printf '%s\n' "$@" >&2
    exit 1
}

run_sudo() {
    if [[ -n "${SSH_CONNECTION:-}" ]]; then
        sudo -n "$@"
    else
        sudo "$@"
    fi
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

if [[ -n "$host_bridge_ipv4" ]]; then
    command -v python3 >/dev/null 2>&1 || die 'Missing required command: python3'
    command -v ufw >/dev/null 2>&1 || die 'Missing required command: ufw'
    python3 - "$host_bridge_ipv4" <<'PY'
import ipaddress
import sys

try:
    address = ipaddress.ip_address(sys.argv[1])
except ValueError:
    raise SystemExit('GUEST_BOOTSTRAP_HOST_IPV4 must be a valid IPv4 address')
if address.version != 4:
    raise SystemExit('GUEST_BOOTSTRAP_HOST_IPV4 must be an IPv4 address')
PY
fi

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

run_sudo true || die 'Guest passwordless sudo is unavailable.'
run_sudo env DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 update
run_sudo env DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 install -y \
    openssh-server

install -d -m 0700 "$HOME/.ssh"
install -m 0600 "$tmp_authorized_keys" "$HOME/.ssh/authorized_keys"

run_sudo install -d -m 0755 /etc/sudoers.d
printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$USER" |
    run_sudo tee /etc/sudoers.d/agent-nopasswd >/dev/null
run_sudo chmod 0440 /etc/sudoers.d/agent-nopasswd
run_sudo visudo -cf /etc/sudoers.d/agent-nopasswd >/dev/null

run_sudo install -d -m 0755 /etc/ssh/sshd_config.d
run_sudo install -m 0644 "$module_dir/90-key-only.conf" /etc/ssh/sshd_config.d/90-key-only.conf
run_sudo sshd -t
run_sudo systemctl enable --now ssh
run_sudo systemctl reload ssh

if [[ -n "$host_bridge_ipv4" ]]; then
    run_sudo ufw allow from "$host_bridge_ipv4" to any port 22 proto tcp
fi

printf 'guest SSH and passwordless sudo bootstrap applied for user: %s\n' "$USER"
