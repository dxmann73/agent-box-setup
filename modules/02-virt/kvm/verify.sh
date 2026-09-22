#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh

Checks the daily-host KVM/libvirt stack: packages, KVM access, the stock default network and
storage pool, resolver modules, and libvirt-guests shutdown policy.

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

package_installed() {
    local -r package="$1"

    dpkg-query -W -f='${Status}\n' "$package" 2>/dev/null | grep -qx 'install ok installed'
}

command_available() {
    command -v "$1" >/dev/null 2>&1
}

bare_metal_x86_64() {
    [[ "$(uname -m)" == x86_64 ]] || return 1
    ! systemd-detect-virt --quiet
}

recorded_member() {
    local -r group="$1"
    local entry members member
    local -a member_list

    entry="$(getent group "$group" || true)"
    [[ -n "$entry" ]] || return 1
    members="${entry##*:}"
    [[ -n "$members" ]] || return 1
    IFS=',' read -r -a member_list <<<"$members"
    for member in "${member_list[@]}"; do
        [[ "$member" == "$USER" ]] && return 0
    done
    return 1
}

session_can_use_kvm_device() {
    [[ -r /dev/kvm && -w /dev/kvm ]]
}

kvm_acceleration() {
    kvm-ok >/dev/null
}

virtiofsd_present() {
    [[ -x /usr/libexec/virtiofsd ]]
}

virsh_uri_is_system() {
    [[ "$(virsh -c qemu:///system uri)" == "qemu:///system" ]]
}

virsh_list_works() {
    virsh -c qemu:///system list --all >/dev/null
}

info_field() {
    local -r object_kind="$1"
    local -r name="$2"
    local -r field="$3"

    virsh -c qemu:///system "${object_kind}-info" "$name" | awk -F: -v field="$field" '
        $1 == field {
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2)
            print $2
            exit
        }
    '
}

pool_target() {
    virsh -c qemu:///system pool-dumpxml default | awk '
        /<target>/ { in_target = 1 }
        in_target && match($0, /<path>[^<]+<\/path>/) {
            text = substr($0, RSTART + 6, RLENGTH - 13)
            print text
            exit
        }
    '
}

default_pool_ready() {
    [[ "$(info_field pool default State)" == running ]] || return 1
    [[ "$(info_field pool default Persistent)" == yes ]] || return 1
    [[ "$(info_field pool default Autostart)" == yes ]] || return 1
    [[ "$(pool_target)" == /var/lib/libvirt/images ]]
}

network_xml() {
    virsh -c qemu:///system net-dumpxml default
}

default_network_ready() {
    local xml

    [[ "$(info_field net default Active)" == yes ]] || return 1
    [[ "$(info_field net default Persistent)" == yes ]] || return 1
    [[ "$(info_field net default Autostart)" == yes ]] || return 1
    [[ "$(info_field net default Bridge)" == virbr0 ]] || return 1
    xml="$(network_xml)"
    grep -Eq "address=['\"]192\\.168\\.122\\.1['\"]" <<<"$xml" || return 1
    grep -Eq "<forward[[:space:]]*/>|<forward[[:space:]][^>]*mode=['\"]nat['\"]" <<<"$xml"
}

nsswitch_order() {
    awk '
        $1 == "hosts:" { ok = ($2 == "files" && $3 == "libvirt" && $4 == "libvirt_guest") }
        END { exit ok ? 0 : 1 }
    ' /etc/nsswitch.conf
}

vms_dir_ready() {
    [[ -d "$HOME/vms" && -w "$HOME/vms" ]]
}

shutdown_policy() {
    local line
    local boot_lines=0

    grep -qx 'ON_SHUTDOWN=suspend' /etc/default/libvirt-guests || return 1
    while IFS= read -r line; do
        [[ "$line" == ON_BOOT=* ]] || continue
        boot_lines=$((boot_lines + 1))
        [[ "$line" == "ON_BOOT=ignore" ]] || return 1
    done </etc/default/libvirt-guests
    ((boot_lines <= 1))
}

unit_enabled() {
    systemctl is-enabled --quiet "$1"
}

unit_active() {
    systemctl is-active --quiet "$1"
}

readonly -a packages=(
    cpu-checker
    qemu-system-x86
    libvirt-daemon-system
    libvirt-clients
    virtinst
    virt-manager
    virt-viewer
    virtiofsd
    libnss-libvirt
)
readonly -a binaries=(
    kvm-ok
    virsh
    virt-install
    virt-viewer
    virt-manager
    qemu-img
)

check 'daily-host x86_64' bare_metal_x86_64

for package in "${packages[@]}"; do
    check "${package} installed" package_installed "$package"
done

for binary in "${binaries[@]}"; do
    check "${binary} available" command_available "$binary"
done

check 'KVM acceleration available' kvm_acceleration
check 'virtiofsd binary' virtiofsd_present
check "${USER} recorded in group libvirt" recorded_member libvirt
check "${USER} recorded in group kvm" recorded_member kvm
check 'this session can use /dev/kvm' session_can_use_kvm_device
check 'system libvirt URI' virsh_uri_is_system
check 'system libvirt connection' virsh_list_works
check 'default storage pool' default_pool_ready
check 'default NAT network' default_network_ready
check 'libvirt resolver modules after files' nsswitch_order
check '~/vms exists and is writable' vms_dir_ready
check 'libvirt-guests suspends on host shutdown' shutdown_policy
check 'libvirtd enabled' unit_enabled libvirtd.service
check 'libvirtd active' unit_active libvirtd.service
check 'libvirt-guests enabled' unit_enabled libvirt-guests.service
check 'libvirt-guests active' unit_active libvirt-guests.service

if ((failures > 0)); then
    printf 'kvm verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'kvm verify passed'
