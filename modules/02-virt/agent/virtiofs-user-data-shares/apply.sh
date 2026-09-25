#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C
export LIBVIRT_DEFAULT_URI="${LIBVIRT_DEFAULT_URI:-qemu:///system}"

trap 'printf "ERROR: virtiofs-user-data-shares apply failed at line %s\n" "$LINENO" >&2' ERR

mode=""
dry_run=0

usage() {
    cat <<'USAGE'
Usage: ./apply.sh --host [--dry-run]
       ./apply.sh --guest

Host mode attaches listed virtiofs devices to the agent VM domain.
Guest mode mounts the listed tags and persists them in fstab.

Share list format:
  USER_DATA_SHARES lines are tag|host path|guest mount path|ro-or-rw

Required host environment:
  AGENT_VM_DOMAIN     libvirt domain name
  USER_DATA_SHARES    newline-separated share list

Required guest environment:
  USER_DATA_SHARES    same share list; host paths are ignored in guest mode

Optional environment:
  USER_DATA_SHARE_XML_DIR  Default: $HOME/vms
  AGENT_VM_XML_PATH        Default: $HOME/vms/$AGENT_VM_DOMAIN.xml
  AGENT_VM_EXPECTED_HOSTNAME
      Guest hostname guard in --guest mode. Default: $AGENT_VM_DOMAIN or agent-vm

Options:
  --host      Run host-side libvirt attach
  --guest     Run guest-side mount and fstab setup
  --dry-run   In host mode, print generated filesystem XML without attaching
  -h, --help  Show this help
USAGE
}

die() {
    printf '%s\n' "$@" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

valid_tag() {
    [[ "$1" =~ ^[A-Za-z0-9_.:-]+$ ]] && [[ "$1" != *'/'* ]]
}

valid_access() {
    [[ "$1" == ro || "$1" == rw ]]
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --host)
            [[ -z "$mode" ]] || die 'Choose exactly one mode: --host or --guest.'
            mode=host
            ;;
        --guest)
            [[ -z "$mode" ]] || die 'Choose exactly one mode: --host or --guest.'
            mode=guest
            ;;
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

[[ -n "$mode" ]] || {
    usage >&2
    exit 2
}

share_lines() {
    local raw_line

    while IFS= read -r raw_line || [[ -n "$raw_line" ]]; do
        [[ -z "$raw_line" || "$raw_line" == \#* ]] && continue
        printf '%s\n' "$raw_line"
    done <<<"${USER_DATA_SHARES:-}"
}

validate_share() {
    local -r tag="$1"
    local -r host_path="$2"
    local -r guest_path="$3"
    local -r access="$4"
    local -r extra="${5:-}"

    [[ -z "$extra" ]] || die "Too many fields in share line for tag ${tag}."
    valid_tag "$tag" || die "Invalid share tag: ${tag}"
    [[ "$host_path" == /* ]] || die "Host path must be absolute for ${tag}: ${host_path}"
    [[ "$guest_path" == /* ]] || die "Guest path must be absolute for ${tag}: ${guest_path}"
    valid_access "$access" || die "Access must be ro or rw for ${tag}: ${access}"
}

require_share_list() {
    [[ -n "${USER_DATA_SHARES:-}" ]] || die 'Missing USER_DATA_SHARES.'
    [[ -n "$(share_lines)" ]] || die 'USER_DATA_SHARES has no usable share lines.'
}

domain_xml_has_memfd_shared() {
    local -r xml="$1"

    python3 -c '
import sys
import xml.etree.ElementTree as ET

root = ET.fromstring(sys.stdin.read())
source = root.find("./memoryBacking/source")
access = root.find("./memoryBacking/access")
sys.exit(
    0
    if source is not None
    and source.get("type") == "memfd"
    and access is not None
    and access.get("mode") == "shared"
    else 1
)
' <<<"$xml"
}

domain_xml_has_share() {
    local -r xml="$1"

    python3 -c '
import os
import sys
import xml.etree.ElementTree as ET

root = ET.fromstring(sys.stdin.read())
tag = os.environ["SHARE_TAG"]
source_path = os.environ["SHARE_HOST_PATH"]
access = os.environ["SHARE_ACCESS"]

for fs in root.findall("./devices/filesystem"):
    driver = fs.find("driver")
    source = fs.find("source")
    target = fs.find("target")
    if target is None or target.get("dir") != tag:
        continue
    readonly = fs.find("readonly") is not None
    ok = (
        fs.get("type") == "mount"
        and fs.get("accessmode") == "passthrough"
        and driver is not None
        and driver.get("type") == "virtiofs"
        and source is not None
        and source.get("dir") == source_path
        and readonly == (access == "ro")
    )
    sys.exit(0 if ok else 2)
sys.exit(1)
' <<<"$xml"
}

domain_xml_has_tag() {
    local -r xml="$1"

    python3 -c '
import os
import sys
import xml.etree.ElementTree as ET

root = ET.fromstring(sys.stdin.read())
tag = os.environ["SHARE_TAG"]

for target in root.findall("./devices/filesystem/target"):
    if target.get("dir") == tag:
        sys.exit(0)
sys.exit(1)
' <<<"$xml"
}

write_filesystem_xml() {
    local -r destination="$1"

    python3 - "$destination" <<'PY'
import os
import sys
import xml.etree.ElementTree as ET

destination = sys.argv[1]
fs = ET.Element("filesystem", {"type": "mount", "accessmode": "passthrough"})
ET.SubElement(fs, "driver", {"type": "virtiofs"})
ET.SubElement(fs, "source", {"dir": os.environ["SHARE_HOST_PATH"]})
ET.SubElement(fs, "target", {"dir": os.environ["SHARE_TAG"]})
if os.environ["SHARE_ACCESS"] == "ro":
    ET.SubElement(fs, "readonly")
ET.indent(fs, space="  ")
if destination == "-":
    ET.ElementTree(fs).write(sys.stdout, encoding="unicode")
    sys.stdout.write("\n")
else:
    ET.ElementTree(fs).write(destination, encoding="unicode")
    with open(destination, "a", encoding="utf-8") as handle:
        handle.write("\n")
PY
}

host_source_allowed() {
    local -r host_path="$1"
    local resolved_source
    local resolved_home

    [[ -d "$host_path" ]] || return 1
    resolved_source="$(readlink -f -- "$host_path")" || return 1
    resolved_home="$(readlink -f -- "$HOME")" || return 1

    [[ "$resolved_source" != / ]] || return 1
    [[ "$resolved_source" != "$resolved_home" ]] || return 1
    [[ "$resolved_source" != "$resolved_home/.ssh" ]] || return 1
    [[ "$resolved_source" != "$resolved_home/Documents" ]] || return 1
}

apply_host_share() {
    local -r tag="$1"
    local -r host_path="$2"
    local -r access="$4"
    local -r xml_path="${USER_DATA_SHARE_XML_DIR}/share-${tag}.xml"
    local share_status
    local live_status

    export SHARE_TAG="$tag" SHARE_HOST_PATH="$host_path" SHARE_ACCESS="$access"

    host_source_allowed "$host_path" || die "Refusing unsafe or missing host source for ${tag}: ${host_path}"

    if ((dry_run)); then
        printf 'filesystem XML for %s:\n' "$tag" >&2
        write_filesystem_xml -
        return 0
    fi

    mkdir -p "$USER_DATA_SHARE_XML_DIR"
    write_filesystem_xml "$xml_path"

    set +e
    domain_xml_has_share "$inactive_xml"
    share_status=$?
    set -e
    if [[ $share_status -eq 0 ]]; then
        printf 'share %s already attached in inactive domain XML\n' "$tag"
    elif [[ $share_status -eq 2 ]] || domain_xml_has_tag "$inactive_xml"; then
        die "Domain already has a filesystem target named ${tag}, but it does not match this module."
    else
        virsh -c qemu:///system attach-device "$AGENT_VM_DOMAIN" "$xml_path" --config
        inactive_xml="$(virsh -c qemu:///system dumpxml --inactive "$AGENT_VM_DOMAIN")"
    fi

    if [[ "$domain_state" == running ]]; then
        set +e
        domain_xml_has_share "$live_xml"
        live_status=$?
        set -e
        if [[ $live_status -eq 0 ]]; then
            printf 'share %s already attached in live domain XML\n' "$tag"
        elif [[ $live_status -eq 2 ]] || domain_xml_has_tag "$live_xml"; then
            die "Live domain already has a filesystem target named ${tag}, but it does not match this module."
        else
            virsh -c qemu:///system attach-device "$AGENT_VM_DOMAIN" "$xml_path" --live
            live_xml="$(virsh -c qemu:///system dumpxml "$AGENT_VM_DOMAIN")"
        fi
    fi
}

apply_host() {
    [[ $dry_run -eq 0 || $mode == host ]] || die '--dry-run is only valid with --host.'
    [[ $EUID -ne 0 ]] || die 'Run as the desktop user, not as root.'
    if systemd-detect-virt --quiet; then
        die "virtiofs-user-data-shares --host applies to daily hosts only. systemd-detect-virt reports $(systemd-detect-virt)."
    fi

    [[ -n "${AGENT_VM_DOMAIN:-}" ]] || die 'Missing AGENT_VM_DOMAIN.'
    [[ "$AGENT_VM_DOMAIN" =~ ^[A-Za-z0-9][A-Za-z0-9_.:-]*$ ]] ||
        die "Invalid AGENT_VM_DOMAIN: ${AGENT_VM_DOMAIN}"
    require_share_list

    require_command python3
    require_command virsh
    require_command readlink
    require_command mkdir
    require_command systemd-detect-virt

    readonly USER_DATA_SHARE_XML_DIR="${USER_DATA_SHARE_XML_DIR:-$HOME/vms}"
    readonly AGENT_VM_XML_PATH="${AGENT_VM_XML_PATH:-$HOME/vms/${AGENT_VM_DOMAIN}.xml}"
    local line
    local tag
    local host_path
    local guest_path
    local access
    local extra

    inactive_xml="$(virsh -c qemu:///system dumpxml --inactive "$AGENT_VM_DOMAIN")" ||
        die "Domain not found: ${AGENT_VM_DOMAIN}"
    domain_xml_has_memfd_shared "$inactive_xml" ||
        die "Domain lacks shared memfd memory backing required by virtiofs: ${AGENT_VM_DOMAIN}"
    domain_state="$(virsh -c qemu:///system domstate "$AGENT_VM_DOMAIN")"
    if [[ "$domain_state" == running ]]; then
        live_xml="$(virsh -c qemu:///system dumpxml "$AGENT_VM_DOMAIN")"
    else
        live_xml=""
    fi

    while IFS= read -r line; do
        IFS='|' read -r tag host_path guest_path access extra <<<"$line"
        validate_share "$tag" "$host_path" "$guest_path" "$access" "${extra:-}"
        apply_host_share "$tag" "$host_path" "$guest_path" "$access"
    done < <(share_lines)

    if ((dry_run)); then
        return 0
    fi

    mkdir -p "$(dirname -- "$AGENT_VM_XML_PATH")"
    virsh -c qemu:///system dumpxml --inactive "$AGENT_VM_DOMAIN" >"$AGENT_VM_XML_PATH"
    printf 'virtiofs user-data shares attached to %s\n' "$AGENT_VM_DOMAIN"
}

fstab_line_present() {
    local -r tag="$1"
    local -r guest_path="$2"
    local -r access="$3"

    awk -v tag="$tag" -v guest_path="$guest_path" -v access="$access" '
        $1 == tag && $2 == guest_path && $3 == "virtiofs" &&
        $4 ~ "(^|,)" access "(,|$)" && $4 ~ /(^|,)nofail(,|$)/ {
            found = 1
        }
        END { exit(found ? 0 : 1) }
    ' /etc/fstab
}

guest_share_link_path() {
    local -r guest_path="$1"

    if [[ "$guest_path" == /mnt/shares/* ]]; then
        printf '%s\n' "$HOME/shares/${guest_path#/mnt/shares/}"
    fi
}

guest_path_is_covered_by_share_link() {
    local guest_path="$1"
    local link_path

    while [[ "$guest_path" != /mnt/shares ]]; do
        link_path="$HOME/shares/${guest_path#/mnt/shares/}"
        if [[ -L "$link_path" ]] && [[ "$(readlink -- "$link_path")" == "$guest_path" ]]; then
            return 0
        fi
        guest_path="$(dirname -- "$guest_path")"
    done
    return 1
}

apply_guest_share() {
    local -r tag="$1"
    local -r guest_path="$3"
    local -r access="$4"
    local tmp
    local link_path

    if ! mountpoint -q "$guest_path"; then
        sudo mount -t virtiofs -o "$access" "$tag" "$guest_path"
    fi

    if ! fstab_line_present "$tag" "$guest_path" "$access"; then
        tmp="$(mktemp)"
        awk -v tag="$tag" -v guest_path="$guest_path" '
            !($1 == tag || ($2 == guest_path && $3 == "virtiofs")) { print }
        ' /etc/fstab >"$tmp"
        printf '%s\t%s\tvirtiofs\t%s,nofail\t0\t0\n' "$tag" "$guest_path" "$access" >>"$tmp"
        sudo install -m 0644 "$tmp" /etc/fstab
        rm -f "$tmp"
    fi

    link_path="$(guest_share_link_path "$guest_path")"
    if [[ -n "$link_path" ]] && ! guest_path_is_covered_by_share_link "$guest_path"; then
        mkdir -p "$(dirname -- "$link_path")"
        ln -sfn "$guest_path" "$link_path"
    fi

    printf 'virtiofs share %s mounted at %s\n' "$tag" "$guest_path"
}

apply_guest() {
    [[ $dry_run -eq 0 ]] || die '--dry-run is only valid with --host.'
    [[ $EUID -ne 0 ]] || die 'Run as the desktop user, not as root.'
    systemd-detect-virt --vm --quiet || die 'This module applies inside a guest VM only.'
    require_share_list

    require_command awk
    require_command findmnt
    require_command mountpoint
    require_command sudo
    require_command systemd-detect-virt

    sudo -n true || die 'Passwordless sudo is required before this module runs.'

    local expected_hostname="${AGENT_VM_EXPECTED_HOSTNAME:-${AGENT_VM_DOMAIN:-agent-vm}}"
    [[ "$(hostname)" == "$expected_hostname" ]] ||
        die "hostname is $(hostname); expected ${expected_hostname}"

    local line
    local tag
    local host_path
    local guest_path
    local access
    local extra

    while IFS= read -r line; do
        IFS='|' read -r tag host_path guest_path access extra <<<"$line"
        validate_share "$tag" "$host_path" "$guest_path" "$access" "${extra:-}"
        sudo install -d -m 0755 "$guest_path"
    done < <(share_lines)

    while IFS= read -r line; do
        IFS='|' read -r tag host_path guest_path access extra <<<"$line"
        validate_share "$tag" "$host_path" "$guest_path" "$access" "${extra:-}"
        apply_guest_share "$tag" "$host_path" "$guest_path" "$access"
    done < <(share_lines)
}

case "$mode" in
    host)
        apply_host
        ;;
    guest)
        apply_guest
        ;;
esac
