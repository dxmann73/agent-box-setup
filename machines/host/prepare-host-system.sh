#!/usr/bin/env bash

# Host prerequisites only. Does not define or create any virtual machine.

set -Eeuo pipefail
trap 'printf "ERROR: host preparation failed at line %s\n" "$LINENO" >&2' ERR

[[ $EUID == 0 && -n ${SUDO_USER:-} && $SUDO_USER != root ]] || {
    printf '%s\n' 'Run with sudo from your normal user account.' >&2
    exit 1
}

readonly setup_user=$SUDO_USER
setup_home=$(getent passwd "$setup_user" | cut -d: -f6)
[[ -n "$setup_home" && -d "$setup_home" ]] || {
    printf 'Could not resolve a home directory for %s.\n' "$setup_user" >&2
    exit 1
}
readonly setup_home

backup_dir="/var/backups/agent-box-setup-$(date +%Y%m%d-%H%M%S)"
readonly backup_dir
mkdir -p "$backup_dir"
cp -a \
    /etc/nsswitch.conf \
    /etc/apt/apt.conf.d \
    /etc/update-manager/release-upgrades \
    "$backup_dir/"

export DEBIAN_FRONTEND=noninteractive
readonly -a packages=(
    git curl wget build-essential pkg-config
    python3 python3-pip python3-venv pipx jq htop btop tmux ripgrep fd-find
    unzip zip ca-certificates gnupg openssh-client ufw
    vlc libreoffice imagemagick ffmpeg inkscape graphicsmagick
    cpu-checker qemu-system-x86 libvirt-daemon-system libvirt-clients
    virtinst virt-manager virt-viewer virtiofsd libnss-libvirt
    unattended-upgrades needrestart
)

apt-get update
apt-get install -y "${packages[@]}"

install -m 0755 -d /etc/apt/keyrings
key_file=$(mktemp /tmp/agent-box-nodesource.XXXXXX)
readonly key_file
trap 'rm -f -- "$key_file"' EXIT
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key -o "$key_file"
gpg --batch --yes --dearmor -o /etc/apt/keyrings/nodesource.gpg "$key_file"
chmod 0644 /etc/apt/keyrings/nodesource.gpg
printf '%s\n' \
    'deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main' \
    > /etc/apt/sources.list.d/nodesource.list
apt-get update
apt-get install -y nodejs

usermod -aG libvirt,kvm "$setup_user"
systemctl enable --now libvirtd
python3 - <<'PY'
from pathlib import Path

p = Path('/etc/nsswitch.conf')
lines = p.read_text().splitlines()
for i, line in enumerate(lines):
    if line.startswith('hosts:'):
        fields = line.split()
        for module in ('libvirt_guest', 'libvirt'):
            if module not in fields:
                fields.insert(2, module)
        lines[i] = ' '.join(fields)
p.write_text('\n'.join(lines) + '\n')
PY

if ! virsh -c qemu:///system net-info default >/dev/null 2>&1; then
    virsh -c qemu:///system net-define /usr/share/libvirt/networks/default.xml
fi
if ! virsh -c qemu:///system net-info default | grep -q 'Active:.*yes'; then
    virsh -c qemu:///system net-start default
fi
virsh -c qemu:///system net-autostart default

if ! virsh -c qemu:///system pool-info default >/dev/null 2>&1; then
    mkdir -p /var/lib/libvirt/images
    virsh -c qemu:///system pool-define-as default dir --target /var/lib/libvirt/images
fi
if ! virsh -c qemu:///system pool-info default | grep -q 'State:.*running'; then
    virsh -c qemu:///system pool-start default
fi
virsh -c qemu:///system pool-autostart default

# Preserve existing firewall exceptions; this local desktop needs no new inbound service.
ufw default deny incoming
ufw default allow outgoing
ufw --force enable

cat > /etc/apt/apt.conf.d/20auto-upgrades <<'CONFIG'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
CONFIG

cat > /etc/apt/apt.conf.d/52unattended-upgrades-local <<'CONFIG'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}:${distro_codename}-updates";
};
Unattended-Upgrade::Origins-Pattern {
    "origin=Google LLC,codename=stable";
    "origin=Node Source";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
CONFIG

mkdir -p /etc/needrestart/conf.d
cat > /etc/needrestart/conf.d/50local.conf <<'CONFIG'
$nrconf{restart} = 'a';
$nrconf{kernelhints} = 0;
CONFIG

sed -i 's/^Prompt=.*/Prompt=lts/' /etc/update-manager/release-upgrades
systemctl enable --now apt-daily.timer apt-daily-upgrade.timer
loginctl enable-linger "$setup_user"

setup_group=$(id -gn "$setup_user")
readonly setup_group
install -d -o "$setup_user" -g "$setup_group" \
    "$setup_home/vms" "$setup_home/system-info"

kvm-ok
node --version
virsh -c qemu:///system list --all
virsh -c qemu:///system net-list --all
virsh -c qemu:///system pool-list --all
ufw status verbose
printf '\nHost system prerequisites complete. No VM created. Configuration backups: %s\n' \
    "$backup_dir"
