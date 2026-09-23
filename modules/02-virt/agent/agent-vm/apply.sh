#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C
export LIBVIRT_DEFAULT_URI="${LIBVIRT_DEFAULT_URI:-qemu:///system}"

trap 'printf "ERROR: agent-vm apply failed at line %s\n" "$LINENO" >&2' ERR

dry_run=0

usage() {
    cat <<'USAGE'
Usage: ./apply.sh [--dry-run]

Creates the agent execution VM domain from an already verified Kubuntu ISO.

Required environment:
  AGENT_BOX_VM_HOSTNAME    libvirt domain name and intended guest hostname
  AGENT_BOX_VM_VCPUS       vCPU count
  AGENT_BOX_VM_MEMORY_MIB  memory in MiB
  AGENT_BOX_VM_DISK_GIB    sparse qcow2 disk size in GiB
  AGENT_NET_NAME           isolated libvirt network name

Optional environment:
  AGENT_BOX_VM_OSINFO      Default: ubuntu24.04
  AGENT_BOX_VM_ISO         Default: /var/lib/libvirt/boot/kubuntu-26.04.1-desktop-amd64.iso
  AGENT_BOX_VM_XML_PATH    Default: ~/vms/$AGENT_BOX_VM_HOSTNAME.xml

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
    AGENT_BOX_VM_HOSTNAME \
    AGENT_BOX_VM_VCPUS \
    AGENT_BOX_VM_MEMORY_MIB \
    AGENT_BOX_VM_DISK_GIB \
    AGENT_NET_NAME
do
    [[ -n "${!variable:-}" ]] || die "Missing required environment variable: ${variable}"
done

require_uint AGENT_BOX_VM_VCPUS
require_uint AGENT_BOX_VM_MEMORY_MIB
require_uint AGENT_BOX_VM_DISK_GIB

[[ "$AGENT_BOX_VM_HOSTNAME" =~ ^[A-Za-z0-9][A-Za-z0-9_.:-]*$ ]] ||
    die "Invalid AGENT_BOX_VM_HOSTNAME: ${AGENT_BOX_VM_HOSTNAME}"
[[ "$AGENT_NET_NAME" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]] ||
    die "Invalid AGENT_NET_NAME: ${AGENT_NET_NAME}"

readonly domain="$AGENT_BOX_VM_HOSTNAME"
readonly network="$AGENT_NET_NAME"
readonly vcpus="$AGENT_BOX_VM_VCPUS"
readonly memory_mib="$AGENT_BOX_VM_MEMORY_MIB"
readonly disk_gib="$AGENT_BOX_VM_DISK_GIB"
readonly osinfo="${AGENT_BOX_VM_OSINFO:-ubuntu24.04}"
readonly iso_path="${AGENT_BOX_VM_ISO:-/var/lib/libvirt/boot/kubuntu-26.04.1-desktop-amd64.iso}"
readonly xml_path="${AGENT_BOX_VM_XML_PATH:-$HOME/vms/${domain}.xml}"

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
    --graphics spice,listen=none
    --video virtio,accel3d=no
    --cdrom "$iso_path"
    --autostart
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
    die "agent-vm applies to daily hosts only. systemd-detect-virt reports $(systemd-detect-virt)."
fi

for binary in virt-install virsh grep; do
    command -v "$binary" >/dev/null 2>&1 || die "Missing required command: ${binary}"
done

[[ -r "$iso_path" ]] || die "ISO is not readable: ${iso_path}"

virsh -c qemu:///system list --all >/dev/null

if virsh -c qemu:///system dominfo "$domain" >/dev/null 2>&1; then
    die "Domain already exists: ${domain}. Review it with ./verify.sh instead of redefining it."
fi

virsh -c qemu:///system net-info "$network" >/dev/null 2>&1 ||
    die "Missing libvirt network: ${network}"
virsh -c qemu:///system net-list --name | grep -Fxq "$network" ||
    die "Libvirt network is not active: ${network}"

"${install_command[@]}"

virsh -c qemu:///system autostart "$domain" >/dev/null
mkdir -p "$(dirname -- "$xml_path")"
virsh -c qemu:///system dumpxml --inactive "$domain" >"$xml_path"

printf 'agent-vm domain created: %s\n' "$domain"
printf 'Saved inactive domain XML: %s\n' "$xml_path"
