#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C
export LIBVIRT_DEFAULT_URI="${LIBVIRT_DEFAULT_URI:-qemu:///system}"

trap 'printf "ERROR: chrome-vm apply failed at line %s\n" "$LINENO" >&2' ERR

dry_run=0

usage() {
    cat <<'USAGE'
Usage: ./apply.sh [--dry-run]

Creates the Chrome browser VM domain from an already verified Kubuntu ISO.

Required environment:
  CHROME_VM_DOMAIN      libvirt domain name
  CHROME_VM_NETWORK     libvirt network name
  CHROME_VM_VCPUS       vCPU count
  CHROME_VM_MEMORY_MIB  memory in MiB
  CHROME_VM_DISK_GIB    sparse qcow2 disk size in GiB
  CHROME_VM_ISO         path to installed Kubuntu desktop ISO

Optional environment:
  CHROME_VM_OSINFO       Default: ubuntu24.04
  CHROME_VM_RENDER_NODE  Default: /dev/dri/renderD128
  CHROME_VM_XML_PATH     Default: ~/vms/$CHROME_VM_DOMAIN.xml

Options:
  --dry-run    Print the virt-install command without creating the domain
  -h, --help   Show this help
USAGE
}

die() {
    printf '%s\n' "$@" >&2
    exit 1
}

shell_quote_command() {
    local arg

    for arg in "$@"; do
        printf '%q ' "$arg"
    done
    printf '\n'
}

require_uint() {
    local -r name="$1"
    local -r value="${!name:-}"

    [[ "$value" =~ ^[1-9][0-9]*$ ]] || die "${name} must be a positive integer."
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)
            dry_run=1
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

for variable in \
    CHROME_VM_DOMAIN \
    CHROME_VM_NETWORK \
    CHROME_VM_VCPUS \
    CHROME_VM_MEMORY_MIB \
    CHROME_VM_DISK_GIB \
    CHROME_VM_ISO
do
    [[ -n "${!variable:-}" ]] || die "Missing required environment variable: ${variable}"
done

require_uint CHROME_VM_VCPUS
require_uint CHROME_VM_MEMORY_MIB
require_uint CHROME_VM_DISK_GIB

[[ "$CHROME_VM_DOMAIN" =~ ^[A-Za-z0-9][A-Za-z0-9_.:-]*$ ]] ||
    die "Invalid CHROME_VM_DOMAIN: ${CHROME_VM_DOMAIN}"
[[ "$CHROME_VM_NETWORK" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]] ||
    die "Invalid CHROME_VM_NETWORK: ${CHROME_VM_NETWORK}"

readonly domain="$CHROME_VM_DOMAIN"
readonly network="$CHROME_VM_NETWORK"
readonly vcpus="$CHROME_VM_VCPUS"
readonly memory_mib="$CHROME_VM_MEMORY_MIB"
readonly disk_gib="$CHROME_VM_DISK_GIB"
readonly iso_path="$CHROME_VM_ISO"
readonly osinfo="${CHROME_VM_OSINFO:-ubuntu24.04}"
readonly render_node="${CHROME_VM_RENDER_NODE:-/dev/dri/renderD128}"
readonly xml_path="${CHROME_VM_XML_PATH:-$HOME/vms/${domain}.xml}"

install_command=(
    virt-install
    --connect qemu:///system
    --name "$domain"
    --osinfo "detect=on,name=${osinfo}"
    --vcpus "$vcpus"
    --cpu "host-passthrough,topology.sockets=1,topology.cores=${vcpus},topology.threads=1"
    --memory "$memory_mib"
    --memballoon model=virtio,freePageReporting=on
    --memorybacking source.type=memfd,access.mode=shared
    --disk "size=${disk_gib},format=qcow2,bus=virtio,discard=unmap"
    --network "network=${network},model=virtio"
    --graphics "spice,listen=none,gl.enable=yes,gl.rendernode=${render_node}"
    --video virtio,accel3d=yes
    --sound ich9
    --cdrom "$iso_path"
    --noautoconsole
)

if ((dry_run)); then
    shell_quote_command "${install_command[@]}"
    exit 0
fi

[[ $EUID -ne 0 ]] || die 'Run as the normal user; the script uses sudo where needed.'

sudo -n true 2>/dev/null ||
    die \
        'sudo credentials are not cached.' \
        'Start the host-sudo-session babysit terminal or run sudo -v, then retry.'

if systemd-detect-virt --quiet; then
    die "chrome-vm applies to daily hosts only. systemd-detect-virt reports $(systemd-detect-virt)."
fi

for binary in virt-install virt-xml virsh id grep; do
    command -v "$binary" >/dev/null 2>&1 || die "Missing required command: ${binary}"
done

[[ -r "$iso_path" ]] || die "ISO is not readable: ${iso_path}"
[[ -e "$render_node" ]] || die "Render node is missing: ${render_node}"
[[ -r "$render_node" ]] || die "Render node is not readable by this session: ${render_node}"

virsh -c qemu:///system list --all >/dev/null

if virsh -c qemu:///system dominfo "$domain" >/dev/null 2>&1; then
    die "Domain already exists: ${domain}. Review it with ./verify.sh instead of redefining it."
fi

virsh -c qemu:///system net-info "$network" >/dev/null 2>&1 ||
    die "Missing libvirt network: ${network}"
virsh -c qemu:///system net-list --name | grep -Fxq "$network" ||
    die "Libvirt network is not active: ${network}"

if ! id -nG libvirt-qemu | tr ' ' '\n' | grep -qx render; then
    sudo usermod -aG render libvirt-qemu
fi

"${install_command[@]}"

virsh -c qemu:///system autostart --disable "$domain" >/dev/null 2>&1 || true
virt-xml "$domain" --edit \
    --xml ./devices/graphics/image/@compression=off \
    --xml ./devices/graphics/jpeg/@compression=never \
    --xml ./devices/graphics/zlib/@compression=never \
    --xml ./devices/graphics/streaming/@mode=off

mkdir -p "$(dirname -- "$xml_path")"
virsh -c qemu:///system dumpxml --inactive "$domain" >"$xml_path"

printf 'chrome-vm domain created: %s\n' "$domain"
printf 'Saved inactive domain XML: %s\n' "$xml_path"
