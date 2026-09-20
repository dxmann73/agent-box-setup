#!/usr/bin/env bash
# Read-only infrastructure check, before personal-browser or agent-VM creation.
set -u -o pipefail
export LC_ALL=C
export LIBVIRT_DEFAULT_URI=qemu:///system

if (($#)); then
    if [[ $# == 1 && ( $1 == --help || $1 == -h ) ]]; then
        printf 'Usage: %s\nChecks host virtualization infrastructure without creating a guest.\n' "$0"
        exit 0
    fi
    printf 'ERROR: this check takes no arguments.\n' >&2
    exit 2
fi

failures=0
check() {
    local label="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        printf '✓ %s\n' "$label"
    else
        printf '✗ %s\n' "$label"
        failures=$((failures + 1))
    fi
}
package_installed() {
    [[ "$(dpkg-query -W -f='${db:Status-Status}' "$1" 2>/dev/null)" == installed ]]
}

printf 'Host virtualization infrastructure (read-only)\n\n'
for binary in virsh virt-install virt-viewer qemu-img kvm-ok python3 ssh curl gpgv sha256sum; do
    check "$binary available" command -v "$binary"
done
check 'KVM acceleration available' kvm-ok
check 'current user can read /dev/kvm' test -r /dev/kvm
check 'current user can write /dev/kvm' test -w /dev/kvm
check 'system libvirt connection works' virsh list --all
check 'default storage pool active' bash -c 'virsh pool-list --name | grep -Fx default'
check 'default storage pool autostarts' bash -c 'virsh pool-list --autostart --name | grep -Fx default'
check 'default network active' bash -c 'virsh net-list --name | grep -Fx default'
check 'default network autostarts' bash -c 'virsh net-list --autostart --name | grep -Fx default'
for module in libvirt libvirt_guest; do
    check "$module host resolver enabled" awk -v module="$module" \
        '$1 == "hosts:" { for (i=2; i<=NF; i++) if ($i == module) found=1 } END { exit !found }' \
        /etc/nsswitch.conf
done
for package in virtiofsd libnss-libvirt; do
    check "$package installed" package_installed "$package"
done
check 'domain-definition directory exists' test -d "$HOME/vms"
check 'domain-definition directory writable' test -w "$HOME/vms"
check 'libvirt-guests saves VMs on host shutdown' \
    grep -qx 'ON_SHUTDOWN=suspend' /etc/default/libvirt-guests
printf '\nResult: %d infrastructure check(s) failed.\n' "$failures"
printf '%s\n' 'Also verify guest-specific resources, signed ISO checksum and network policy before installation.'
((failures == 0))
