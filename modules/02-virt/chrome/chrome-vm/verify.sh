#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C
export LIBVIRT_DEFAULT_URI="${LIBVIRT_DEFAULT_URI:-qemu:///system}"

failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh

Checks the Chrome browser VM domain definition against the exported deployment values.

Required environment:
  CHROME_VM_DOMAIN      libvirt domain name
  CHROME_VM_NETWORK     libvirt network name
  CHROME_VM_VCPUS       vCPU count
  CHROME_VM_MEMORY_MIB  memory in MiB
  CHROME_VM_DISK_GIB    sparse qcow2 disk size in GiB
  CHROME_VM_ISO         path to installed Kubuntu desktop ISO

Optional environment:
  CHROME_VM_RENDER_NODE  Default: /dev/dri/renderD128
  CHROME_VM_XML_PATH     Default: ~/vms/$CHROME_VM_DOMAIN.xml

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
        CHROME_VM_DOMAIN \
        CHROME_VM_NETWORK \
        CHROME_VM_VCPUS \
        CHROME_VM_MEMORY_MIB \
        CHROME_VM_DISK_GIB \
        CHROME_VM_ISO
    do
        [[ -n "${!variable:-}" ]] || return 1
    done
}

positive_integer() {
    [[ "${!1:-}" =~ ^[1-9][0-9]*$ ]]
}

valid_environment() {
    [[ "$CHROME_VM_DOMAIN" =~ ^[A-Za-z0-9][A-Za-z0-9_.:-]*$ ]] || return 1
    [[ "$CHROME_VM_NETWORK" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]] || return 1
    positive_integer CHROME_VM_VCPUS || return 1
    positive_integer CHROME_VM_MEMORY_MIB || return 1
    positive_integer CHROME_VM_DISK_GIB
}

domain_exists() {
    virsh -c qemu:///system dominfo "$CHROME_VM_DOMAIN" >/dev/null 2>&1
}

network_active() {
    virsh -c qemu:///system net-list --name | grep -Fxq "$CHROME_VM_NETWORK"
}

autostart_disabled() {
    virsh -c qemu:///system dominfo "$CHROME_VM_DOMAIN" |
        grep -qx 'Autostart:      disable'
}

render_group_ready() {
    id -nG libvirt-qemu | tr ' ' '\n' | grep -qx render
}

domain_xml_matches() {
    local xml

    xml="$(virsh -c qemu:///system dumpxml --inactive "$CHROME_VM_DOMAIN")" || return 1
    python3 -c '
import os
import sys
import xml.etree.ElementTree as ET

root = ET.fromstring(sys.stdin.read())
expected_memory_kib = int(os.environ["CHROME_VM_MEMORY_MIB"]) * 1024

def has_spice_gl():
    for graphics in root.findall("./devices/graphics"):
        if graphics.get("type") != "spice":
            continue
        gl = graphics.find("gl")
        if gl is None or gl.get("enable") != "yes":
            continue
        return gl.get("rendernode") == os.environ.get("CHROME_VM_RENDER_NODE", "/dev/dri/renderD128")
    return False

def has_virtio_3d():
    for model in root.findall("./devices/video/model"):
        accel = model.find("acceleration")
        if model.get("type") == "virtio" and accel is not None and accel.get("accel3d") == "yes":
            return True
    return False

def has_network():
    for iface in root.findall("./devices/interface"):
        source = iface.find("source")
        model = iface.find("model")
        if source is None or model is None:
            continue
        if source.get("network") == os.environ["CHROME_VM_NETWORK"] and model.get("type") == "virtio":
            return True
    return False

def has_audio():
    return any(sound.get("model") == "ich9" for sound in root.findall("./devices/sound"))

checks = [
    root.findtext("name") == os.environ["CHROME_VM_DOMAIN"],
    root.findtext("vcpu") == os.environ["CHROME_VM_VCPUS"],
    int(root.findtext("memory")) == expected_memory_kib,
    int(root.findtext("currentMemory")) == expected_memory_kib,
    has_network(),
    has_spice_gl(),
    has_virtio_3d(),
    has_audio(),
]
sys.exit(0 if all(checks) else 1)
' <<<"$xml"
}

live_xml_matches_when_running() {
    local state
    local xml

    state="$(virsh -c qemu:///system domstate "$CHROME_VM_DOMAIN")" || return 1
    [[ "$state" == running ]] || return 0

    xml="$(virsh -c qemu:///system dumpxml "$CHROME_VM_DOMAIN")" || return 1
    python3 -c '
import os
import sys
import xml.etree.ElementTree as ET

root = ET.fromstring(sys.stdin.read())
render_node = os.environ.get("CHROME_VM_RENDER_NODE", "/dev/dri/renderD128")

spice_gl = False
for graphics in root.findall("./devices/graphics"):
    gl = graphics.find("gl")
    if graphics.get("type") == "spice" and gl is not None:
        spice_gl = gl.get("enable") == "yes" and gl.get("rendernode") == render_node

virtio_3d = False
for model in root.findall("./devices/video/model"):
    accel = model.find("acceleration")
    if model.get("type") == "virtio" and accel is not None and accel.get("accel3d") == "yes":
        virtio_3d = True

sys.exit(0 if spice_gl and virtio_3d else 1)
' <<<"$xml"
}

disk_size_matches() {
    local capacity
    local expected_bytes
    local target

    target="$(
        virsh -c qemu:///system domblklist --details "$CHROME_VM_DOMAIN" |
            awk '$2 == "disk" { print $3; exit }'
    )"
    [[ -n "$target" ]] || return 1

    expected_bytes=$((CHROME_VM_DISK_GIB * 1024 * 1024 * 1024))
    capacity="$(
        virsh -c qemu:///system domblkinfo --bytes "$CHROME_VM_DOMAIN" "$target" |
            awk -F: '$1 == "Capacity" { gsub(/[^0-9]/, "", $2); print $2; exit }'
    )"
    [[ "$capacity" == "$expected_bytes" ]]
}

xml_path_ready() {
    [[ -r "$CHROME_VM_XML_PATH" ]] || return 1
    grep -q "<name>${CHROME_VM_DOMAIN}</name>" "$CHROME_VM_XML_PATH" || return 1
    grep -q "<acceleration accel3d='yes'/>" "$CHROME_VM_XML_PATH"
}

required_environment_present ||
    die \
        'Missing chrome-vm environment.' \
        'Export CHROME_VM_DOMAIN, CHROME_VM_NETWORK, CHROME_VM_VCPUS, CHROME_VM_MEMORY_MIB,' \
        'CHROME_VM_DISK_GIB and CHROME_VM_ISO before running verify.sh.'

readonly CHROME_VM_RENDER_NODE="${CHROME_VM_RENDER_NODE:-/dev/dri/renderD128}"
readonly CHROME_VM_XML_PATH="${CHROME_VM_XML_PATH:-$HOME/vms/${CHROME_VM_DOMAIN}.xml}"
export CHROME_VM_RENDER_NODE CHROME_VM_XML_PATH

check 'daily host, not guest' bare_metal_host
check 'environment values valid' valid_environment
check 'virsh available' command_available virsh
check 'awk available' command_available awk
check 'python3 available' command_available python3
check 'system libvirt connection' virsh -c qemu:///system list --all
check 'referenced ISO readable' test -r "$CHROME_VM_ISO"
check 'referenced render node exists' test -e "$CHROME_VM_RENDER_NODE"
check 'browser network active' network_active
check 'chrome-vm domain exists' domain_exists
check 'domain XML matches role values' domain_xml_matches
check 'live 3D configured when running' live_xml_matches_when_running
check 'domain disk virtual size matches' disk_size_matches
check 'domain autostart disabled' autostart_disabled
check 'libvirt-qemu has render access' render_group_ready
check 'saved inactive domain XML present' xml_path_ready

if ((failures > 0)); then
    printf 'chrome-vm verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'chrome-vm verify passed'
