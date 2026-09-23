#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C
export LIBVIRT_DEFAULT_URI="${LIBVIRT_DEFAULT_URI:-qemu:///system}"

failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh

Checks the agent execution VM domain definition against the exported deployment values.

Required environment:
  AGENT_BOX_VM_HOSTNAME    libvirt domain name and intended guest hostname
  AGENT_BOX_VM_VCPUS       vCPU count
  AGENT_BOX_VM_MEMORY_MIB  memory in MiB
  AGENT_BOX_VM_DISK_GIB    sparse qcow2 disk size in GiB
  AGENT_NET_NAME           isolated libvirt network name

Optional environment:
  AGENT_BOX_VM_ISO         Default: /var/lib/libvirt/boot/kubuntu-26.04.1-desktop-amd64.iso
  AGENT_BOX_VM_XML_PATH    Default: ~/vms/$AGENT_BOX_VM_HOSTNAME.xml

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

die() {
    printf '%s\n' "$@" >&2
    exit 2
}

command_available() {
    command -v "$1" >/dev/null 2>&1
}

bare_metal_host() {
    ! systemd-detect-virt --quiet
}

required_environment_present() {
    local variable

    for variable in \
        AGENT_BOX_VM_HOSTNAME \
        AGENT_BOX_VM_VCPUS \
        AGENT_BOX_VM_MEMORY_MIB \
        AGENT_BOX_VM_DISK_GIB \
        AGENT_NET_NAME
    do
        [[ -n "${!variable:-}" ]] || return 1
    done
}

positive_integer() {
    [[ "${!1:-}" =~ ^[1-9][0-9]*$ ]]
}

valid_environment() {
    [[ "$AGENT_BOX_VM_HOSTNAME" =~ ^[A-Za-z0-9][A-Za-z0-9_.:-]*$ ]] || return 1
    [[ "$AGENT_NET_NAME" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]] || return 1
    positive_integer AGENT_BOX_VM_VCPUS || return 1
    positive_integer AGENT_BOX_VM_MEMORY_MIB || return 1
    positive_integer AGENT_BOX_VM_DISK_GIB
}

domain_exists() {
    virsh -c qemu:///system dominfo "$AGENT_BOX_VM_HOSTNAME" >/dev/null 2>&1
}

network_active() {
    virsh -c qemu:///system net-list --name | grep -Fxq "$AGENT_NET_NAME"
}

autostart_enabled() {
    virsh -c qemu:///system dominfo "$AGENT_BOX_VM_HOSTNAME" |
        grep -qx 'Autostart:      enable'
}

domain_xml_matches() {
    local xml

    xml="$(virsh -c qemu:///system dumpxml --inactive "$AGENT_BOX_VM_HOSTNAME")" || return 1
    python3 -c '
import os
import sys
import xml.etree.ElementTree as ET

root = ET.fromstring(sys.stdin.read())
expected_memory_kib = int(os.environ["AGENT_BOX_VM_MEMORY_MIB"]) * 1024

def has_agent_network():
    for iface in root.findall("./devices/interface"):
        source = iface.find("source")
        model = iface.find("model")
        if source is None or model is None:
            continue
        if source.get("network") == os.environ["AGENT_NET_NAME"] and model.get("type") == "virtio":
            return True
    return False

def has_local_spice():
    for graphics in root.findall("./devices/graphics"):
        if graphics.get("type") != "spice":
            continue
        listen = graphics.find("listen")
        if listen is not None and listen.get("type") != "none":
            return False
        return graphics.get("listen") in (None, "none")
    return False

def has_virtio_2d():
    for model in root.findall("./devices/video/model"):
        accel = model.find("acceleration")
        if model.get("type") != "virtio":
            continue
        return accel is None or accel.get("accel3d") in (None, "no")
    return False

def has_memfd_shared():
    source = root.find("./memoryBacking/source")
    access = root.find("./memoryBacking/access")
    return (
        source is not None
        and source.get("type") == "memfd"
        and access is not None
        and access.get("mode") == "shared"
    )

def has_virtio_balloon():
    for memballoon in root.findall("./devices/memballoon"):
        if memballoon.get("model") == "virtio":
            return True
    return False

checks = [
    root.findtext("name") == os.environ["AGENT_BOX_VM_HOSTNAME"],
    root.findtext("vcpu") == os.environ["AGENT_BOX_VM_VCPUS"],
    int(root.findtext("memory")) == expected_memory_kib,
    int(root.findtext("currentMemory")) == expected_memory_kib,
    root.find("./os/loader") is None,
    has_agent_network(),
    has_local_spice(),
    has_virtio_2d(),
    has_memfd_shared(),
    has_virtio_balloon(),
]
sys.exit(0 if all(checks) else 1)
' <<<"$xml"
}

live_xml_matches_when_running() {
    local state
    local xml

    state="$(virsh -c qemu:///system domstate "$AGENT_BOX_VM_HOSTNAME")" || return 1
    [[ "$state" == running ]] || return 0

    xml="$(virsh -c qemu:///system dumpxml "$AGENT_BOX_VM_HOSTNAME")" || return 1
    python3 -c '
import sys
import xml.etree.ElementTree as ET

root = ET.fromstring(sys.stdin.read())

local_spice = False
for graphics in root.findall("./devices/graphics"):
    if graphics.get("type") != "spice":
        continue
    listen = graphics.find("listen")
    local_spice = graphics.get("listen") in (None, "none") and (
        listen is None or listen.get("type") == "none"
    )

virtio_2d = False
for model in root.findall("./devices/video/model"):
    accel = model.find("acceleration")
    if model.get("type") == "virtio":
        virtio_2d = accel is None or accel.get("accel3d") in (None, "no")

sys.exit(0 if local_spice and virtio_2d else 1)
' <<<"$xml"
}

disk_size_matches() {
    local capacity
    local expected_bytes
    local target

    target="$(
        virsh -c qemu:///system domblklist --details "$AGENT_BOX_VM_HOSTNAME" |
            awk '$2 == "disk" { print $3; exit }'
    )"
    [[ -n "$target" ]] || return 1

    expected_bytes=$((AGENT_BOX_VM_DISK_GIB * 1024 * 1024 * 1024))
    capacity="$(
        virsh -c qemu:///system domblkinfo --bytes "$AGENT_BOX_VM_HOSTNAME" "$target" 2>/dev/null |
            awk -F: '$1 == "Capacity" { gsub(/[^0-9]/, "", $2); print $2; exit }'
    )"
    if [[ -z "$capacity" ]]; then
        capacity="$(
            virsh -c qemu:///system domblkinfo "$AGENT_BOX_VM_HOSTNAME" "$target" |
                awk -F: '$1 == "Capacity" { gsub(/[^0-9]/, "", $2); print $2; exit }'
        )"
    fi
    [[ "$capacity" == "$expected_bytes" ]]
}

xml_path_ready() {
    [[ -r "$AGENT_BOX_VM_XML_PATH" ]] || return 1
    grep -q "<name>${AGENT_BOX_VM_HOSTNAME}</name>" "$AGENT_BOX_VM_XML_PATH" || return 1
    grep -q "<source type='memfd'/>" "$AGENT_BOX_VM_XML_PATH" || return 1
    ! grep -q "accel3d='yes'" "$AGENT_BOX_VM_XML_PATH"
}

required_environment_present ||
    die \
        'Missing agent-vm environment.' \
        'Export AGENT_BOX_VM_HOSTNAME, AGENT_BOX_VM_VCPUS, AGENT_BOX_VM_MEMORY_MIB,' \
        'AGENT_BOX_VM_DISK_GIB and AGENT_NET_NAME before running verify.sh.'

readonly AGENT_BOX_VM_ISO="${AGENT_BOX_VM_ISO:-/var/lib/libvirt/boot/kubuntu-26.04.1-desktop-amd64.iso}"
readonly AGENT_BOX_VM_XML_PATH="${AGENT_BOX_VM_XML_PATH:-$HOME/vms/${AGENT_BOX_VM_HOSTNAME}.xml}"
export AGENT_BOX_VM_ISO AGENT_BOX_VM_XML_PATH

check 'daily host, not guest' bare_metal_host
check 'environment values valid' valid_environment
check 'virsh available' command_available virsh
check 'awk available' command_available awk
check 'python3 available' command_available python3
check 'system libvirt connection' virsh -c qemu:///system list --all
check 'referenced ISO readable' test -r "$AGENT_BOX_VM_ISO"
check 'agent network active' network_active
check 'agent-vm domain exists' domain_exists
check 'domain XML matches role values' domain_xml_matches
check 'live 2D console configured when running' live_xml_matches_when_running
check 'domain disk virtual size matches' disk_size_matches
check 'domain autostart enabled' autostart_enabled
check 'saved inactive domain XML present' xml_path_ready

if ((failures > 0)); then
    printf 'agent-vm verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'agent-vm verify passed'
