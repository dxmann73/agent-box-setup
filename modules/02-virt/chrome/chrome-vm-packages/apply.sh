#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

trap 'printf "ERROR: chrome-vm-packages apply failed at line %s\n" "$LINENO" >&2' ERR

usage() {
    cat <<'USAGE'
Usage: ./apply.sh

Run inside the browser guest after guest-ssh-sudo-bootstrap and guest-integration.

Environment:
  CHROME_VM_EXPECTED_HOSTNAME  Expected guest hostname. Default: chrome-vm

Options:
  -h, --help   Show this help
USAGE
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
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

readonly expected_hostname="${CHROME_VM_EXPECTED_HOSTNAME:-chrome-vm}"
readonly chrome_keyring=/usr/share/keyrings/google-chrome.gpg
readonly chrome_list=/etc/apt/sources.list.d/google-chrome.list
readonly unattended_google=/etc/apt/apt.conf.d/51unattended-upgrades-google-chrome

[[ $EUID -ne 0 ]] || die 'Run as the desktop user, not as root.'
systemd-detect-virt --vm --quiet || die 'This module applies inside a guest VM only.'
[[ "$(hostname)" == "$expected_hostname" ]] ||
    die "hostname is $(hostname); expected ${expected_hostname}"

for binary in curl gpg grep install sudo systemctl; do
    command -v "$binary" >/dev/null 2>&1 || die "Missing required command: ${binary}"
done

sudo -n true || die 'Passwordless sudo is required before this module runs.'

sudo env DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 update
sudo env DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 install -y \
    ca-certificates \
    curl \
    gnupg \
    unattended-upgrades

sudo install -d -m 0755 /usr/share/keyrings
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub |
    sudo gpg --dearmor --yes -o "$chrome_keyring"
sudo chmod 0644 "$chrome_keyring"

printf 'deb [arch=amd64 signed-by=%s] https://dl.google.com/linux/chrome/deb/ stable main\n' \
    "$chrome_keyring" | sudo tee "$chrome_list" >/dev/null

sudo env DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 update
sudo env DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 install -y \
    google-chrome-stable

sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'CONFIG'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
CONFIG

sudo tee "$unattended_google" >/dev/null <<'CONFIG'
Unattended-Upgrade::Origins-Pattern {
        "origin=Google LLC,codename=stable";
};
CONFIG

sudo systemctl enable --now apt-daily.timer apt-daily-upgrade.timer

printf '%s\n' 'chrome-vm-packages applied'
