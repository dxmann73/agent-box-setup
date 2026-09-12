#!/usr/bin/env bash

# Deterministic privileged baseline for the physical host. It never creates a
# virtual machine, configures a coding-agent provider, or makes host sudo
# passwordless. Run it with sudo from the normal desktop user account.

set -Eeuo pipefail
trap 'printf "ERROR: host baseline failed at line %s\n" "$LINENO" >&2' ERR

[[ $EUID -eq 0 && -n ${SUDO_USER:-} && $SUDO_USER != root ]] || {
    printf '%s\n' 'Run with sudo from your normal desktop user account.' >&2
    exit 1
}

readonly setup_user="$SUDO_USER"
setup_home="$(getent passwd "$setup_user" | awk -F: 'NR == 1 { print $6 }')"
[[ -n "$setup_home" && -d "$setup_home" ]] || {
    printf 'Could not resolve a home directory for %s.\n' "$setup_user" >&2
    exit 1
}
readonly setup_home

backup_dir="/var/backups/agent-box-setup-$(date +%Y%m%d-%H%M%S)"
backup_created=0

create_backup_dir() {
    if [[ $backup_created -eq 0 ]]; then
        install -d -m 0700 "$backup_dir"
        backup_created=1
    fi
}

backup_file() {
    local -r file="$1"
    [[ -e "$file" ]] || return 0

    create_backup_dir
    cp -a --parents "$file" "$backup_dir"
}

write_managed_file() {
    local -r destination="$1"
    local -r mode="$2"
    local temporary

    temporary="$(mktemp)"
    cat >"$temporary"
    if ! cmp -s "$temporary" "$destination" 2>/dev/null; then
        backup_file "$destination"
        install -D -m "$mode" "$temporary" "$destination"
    fi
    rm -f -- "$temporary"
}

ensure_libvirt_name_resolution() {
    local temporary

    temporary="$(mktemp)"
    python3 - /etc/nsswitch.conf "$temporary" <<'PY'
from pathlib import Path
import sys

source = Path(sys.argv[1])
destination = Path(sys.argv[2])
lines = source.read_text().splitlines()
for index, line in enumerate(lines):
    if line.startswith("hosts:"):
        fields = line.split()
        for module in ("libvirt_guest", "libvirt"):
            if module not in fields:
                fields.insert(2, module)
        lines[index] = " ".join(fields)
        break
else:
    raise SystemExit("No hosts: entry found in /etc/nsswitch.conf")
destination.write_text("\n".join(lines) + "\n")
PY

    if ! cmp -s "$temporary" /etc/nsswitch.conf; then
        backup_file /etc/nsswitch.conf
        install -m 0644 "$temporary" /etc/nsswitch.conf
    fi
    rm -f -- "$temporary"
}

ensure_locale_sources() {
    local temporary

    temporary="$(mktemp)"
    sed \
        -e 's/^[[:space:]#]*en_US.UTF-8[[:space:]]\+UTF-8/en_US.UTF-8 UTF-8/' \
        -e 's/^[[:space:]#]*de_DE.UTF-8[[:space:]]\+UTF-8/de_DE.UTF-8 UTF-8/' \
        /etc/locale.gen >"$temporary"
    if ! cmp -s "$temporary" /etc/locale.gen; then
        backup_file /etc/locale.gen
        install -m 0644 "$temporary" /etc/locale.gen
    fi
    rm -f -- "$temporary"
}

export DEBIAN_FRONTEND=noninteractive
readonly -a baseline_packages=(
    ca-certificates curl gnupg locales openssh-client ufw
    unattended-upgrades needrestart
    cpu-checker qemu-system-x86 libvirt-daemon-system libvirt-clients
    virtinst virt-manager virt-viewer virtiofsd libnss-libvirt
)

apt-get update
apt-get install -y "${baseline_packages[@]}"

ensure_locale_sources
locale-gen en_US.UTF-8 de_DE.UTF-8
write_managed_file /etc/default/locale 0644 <<'CONFIG'
LANG=en_US.UTF-8
LC_ADDRESS=de_DE.UTF-8
LC_MEASUREMENT=de_DE.UTF-8
LC_MONETARY=de_DE.UTF-8
LC_NAME=de_DE.UTF-8
LC_NUMERIC=de_DE.UTF-8
LC_PAPER=de_DE.UTF-8
LC_TELEPHONE=de_DE.UTF-8
LC_TIME=de_DE.UTF-8
LANGUAGE=en_US
CONFIG

usermod -aG libvirt,kvm "$setup_user"
systemctl enable --now libvirtd
ensure_libvirt_name_resolution

if ! virsh -c qemu:///system net-info default >/dev/null 2>&1; then
    virsh -c qemu:///system net-define /usr/share/libvirt/networks/default.xml
fi
if ! virsh -c qemu:///system net-info default | grep -q 'Active:.*yes'; then
    virsh -c qemu:///system net-start default
fi
virsh -c qemu:///system net-autostart default

if ! virsh -c qemu:///system pool-info default >/dev/null 2>&1; then
    install -d -m 0755 /var/lib/libvirt/images
    virsh -c qemu:///system pool-define-as default dir --target /var/lib/libvirt/images
fi
if ! virsh -c qemu:///system pool-info default | grep -q 'State:.*running'; then
    virsh -c qemu:///system pool-start default
fi
virsh -c qemu:///system pool-autostart default

# Preserve existing firewall exceptions; the host baseline opens no new service.
ufw default deny incoming
ufw default allow outgoing
ufw --force enable

write_managed_file /etc/apt/apt.conf.d/20auto-upgrades 0644 <<'CONFIG'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
CONFIG

write_managed_file /etc/needrestart/conf.d/50local.conf 0644 <<'CONFIG'
$nrconf{restart} = 'a';
$nrconf{kernelhints} = 0;
CONFIG

if ! grep -qx 'Prompt=lts' /etc/update-manager/release-upgrades; then
    backup_file /etc/update-manager/release-upgrades
    sed -i 's/^Prompt=.*/Prompt=lts/' /etc/update-manager/release-upgrades
fi
systemctl enable --now apt-daily.timer apt-daily-upgrade.timer
loginctl enable-linger "$setup_user"

setup_group="$(id -gn "$setup_user")"
install -d -o "$setup_user" -g "$setup_group" "$setup_home/vms" "$setup_home/system-info"

kvm-ok
virsh -c qemu:///system list --all
virsh -c qemu:///system net-list --all
virsh -c qemu:///system pool-list --all
ufw status verbose
if [[ $backup_created -eq 1 ]]; then
    printf '\nHost baseline complete. Backups written to: %s\n' "$backup_dir"
else
    printf '\nHost baseline complete. No tracked configuration files changed.\n'
fi
