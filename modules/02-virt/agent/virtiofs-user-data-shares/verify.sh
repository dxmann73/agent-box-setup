#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C
export LIBVIRT_DEFAULT_URI="${LIBVIRT_DEFAULT_URI:-qemu:///system}"

mode=""
failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh --host
       ./verify.sh --guest

Host mode checks listed agent VM libvirt filesystem devices.
Guest mode checks listed mounted virtiofs shares.

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
  --host      Run host-side checks
  --guest     Run guest-side checks
  -h, --help  Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --host)
            [[ -z "$mode" ]] || {
                printf '%s\n' 'Choose exactly one mode: --host or --guest.' >&2
                exit 2
            }
            mode=host
            ;;
        --guest)
            [[ -z "$mode" ]] || {
                printf '%s\n' 'Choose exactly one mode: --host or --guest.' >&2
                exit 2
            }
            mode=guest
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

valid_tag_value() {
    [[ "$1" =~ ^[A-Za-z0-9_.:-]+$ ]] && [[ "$1" != *'/'* ]]
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

    [[ -z "$extra" ]] || return 1
    valid_tag_value "$tag" || return 1
    [[ "$host_path" == /* ]] || return 1
    [[ "$guest_path" == /* ]] || return 1
    [[ "$access" == ro || "$access" == rw ]]
}

share_list_present() {
    [[ -n "${USER_DATA_SHARES:-}" ]] || return 1
    [[ -n "$(share_lines)" ]]
}

bare_metal_host() {
    ! systemd-detect-virt --quiet
}

valid_domain_name() {
    [[ "${AGENT_VM_DOMAIN:-}" =~ ^[A-Za-z0-9][A-Za-z0-9_.:-]*$ ]]
}

domain_exists() {
    virsh -c qemu:///system dominfo "$AGENT_VM_DOMAIN" >/dev/null 2>&1
}

domain_has_memfd_shared() {
    local xml

    xml="$(virsh -c qemu:///system dumpxml --inactive "$AGENT_VM_DOMAIN")" || return 1
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

xml_has_share() {
    local -r xml="$1"

    python3 -c '
import os
import sys
import xml.etree.ElementTree as ET

root = ET.fromstring(sys.stdin.read())
tag = os.environ["SHARE_TAG"]
source_path = os.environ["SHARE_HOST_PATH"]
access = os.environ["SHARE_ACCESS"]
filesystems = [root] if root.tag == "filesystem" else root.findall("./devices/filesystem")

for fs in filesystems:
    driver = fs.find("driver")
    source = fs.find("source")
    target = fs.find("target")
    if target is None or target.get("dir") != tag:
        continue
    readonly = fs.find("readonly") is not None
    checks = [
        fs.get("type") == "mount",
        fs.get("accessmode") == "passthrough",
        driver is not None and driver.get("type") == "virtiofs",
        source is not None and source.get("dir") == source_path,
        readonly == (access == "ro"),
    ]
    sys.exit(0 if all(checks) else 1)
sys.exit(1)
' <<<"$xml"
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

inactive_domain_has_share() {
    local xml

    xml="$(virsh -c qemu:///system dumpxml --inactive "$AGENT_VM_DOMAIN")" || return 1
    xml_has_share "$xml"
}

live_domain_has_share_when_running() {
    local state
    local xml

    state="$(virsh -c qemu:///system domstate "$AGENT_VM_DOMAIN")" || return 1
    [[ "$state" == running ]] || return 0
    xml="$(virsh -c qemu:///system dumpxml "$AGENT_VM_DOMAIN")" || return 1
    xml_has_share "$xml"
}

filesystem_xml_ready() {
    local -r xml_path="${USER_DATA_SHARE_XML_DIR}/share-${SHARE_TAG}.xml"

    [[ -r "$xml_path" ]] || return 1
    xml_has_share "$(cat "$xml_path")"
}

saved_domain_xml_ready() {
    [[ -r "$AGENT_VM_XML_PATH" ]] || return 1
    xml_has_share "$(cat "$AGENT_VM_XML_PATH")"
}

inside_guest() {
    systemd-detect-virt --vm --quiet
}

expected_hostname_matches() {
    local expected_hostname="${AGENT_VM_EXPECTED_HOSTNAME:-${AGENT_VM_DOMAIN:-agent-vm}}"

    [[ "$(hostname)" == "$expected_hostname" ]]
}

mount_ready() {
    local -r tag="$1"
    local -r guest_path="$2"
    local -r access="$3"
    local line
    local fstype
    local source
    local options

    line="$(findmnt -rn --target "$guest_path" --output FSTYPE,SOURCE,OPTIONS)" || return 1
    read -r fstype source options <<<"$line"
    [[ "$fstype" == virtiofs ]] || return 1
    [[ "$source" == "$tag" ]] || return 1
    [[ ",${options}," == *,"${access}",* ]]
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

share_symlink_ready() {
    local -r guest_path="$1"
    local link_path

    [[ "$guest_path" == /mnt/shares/* ]] || return 0
    link_path="$HOME/shares/${guest_path#/mnt/shares/}"
    [[ -L "$link_path" ]] || return 1
    [[ "$(readlink -- "$link_path")" == "$guest_path" ]]
}

verify_host_share() {
    local -r tag="$1"
    local -r host_path="$2"
    local -r access="$4"

    export SHARE_TAG="$tag" SHARE_HOST_PATH="$host_path" SHARE_ACCESS="$access"

    check "share ${tag} source passes built-in refusal list" host_source_allowed "$host_path"
    check "share ${tag} inactive domain XML" inactive_domain_has_share
    check "share ${tag} live domain XML when running" live_domain_has_share_when_running
    check "share ${tag} filesystem XML saved" filesystem_xml_ready
    check "share ${tag} saved inactive domain XML" saved_domain_xml_ready
}

verify_guest_share() {
    local -r tag="$1"
    local -r guest_path="$3"
    local -r access="$4"

    check "share ${tag} mounted from virtiofs tag with ${access}" mount_ready "$tag" "$guest_path" "$access"
    check "share ${tag} fstab line present" fstab_line_present "$tag" "$guest_path" "$access"
    check "share ${tag} home symlink present when under /mnt/shares" share_symlink_ready "$guest_path"
}

verify_share_lines() {
    local line
    local tag
    local host_path
    local guest_path
    local access
    local extra
    local count=0
    local invalid=0

    while IFS= read -r line; do
        IFS='|' read -r tag host_path guest_path access extra <<<"$line"
        if validate_share "$tag" "$host_path" "$guest_path" "$access" "${extra:-}"; then
            count=$((count + 1))
        else
            printf 'not ok - invalid share line: %s\n' "$line" >&2
            invalid=1
        fi
    done < <(share_lines)

    [[ $count -gt 0 && $invalid -eq 0 ]]
}

verify_host() {
    [[ -n "${AGENT_VM_DOMAIN:-}" ]] || die 'Missing AGENT_VM_DOMAIN.'

    readonly USER_DATA_SHARE_XML_DIR="${USER_DATA_SHARE_XML_DIR:-$HOME/vms}"
    readonly AGENT_VM_XML_PATH="${AGENT_VM_XML_PATH:-$HOME/vms/${AGENT_VM_DOMAIN}.xml}"

    check 'daily host, not guest' bare_metal_host
    check 'share list present' share_list_present
    check 'share lines valid' verify_share_lines
    check 'agent VM domain name valid' valid_domain_name
    check 'virsh available' command_available virsh
    check 'python3 available' command_available python3
    check 'readlink available' command_available readlink
    check 'system libvirt connection' virsh -c qemu:///system list --all
    check 'agent VM domain exists' domain_exists
    check 'domain has shared memfd backing for virtiofs' domain_has_memfd_shared

    local line
    local tag
    local host_path
    local guest_path
    local access
    local extra

    while IFS= read -r line; do
        IFS='|' read -r tag host_path guest_path access extra <<<"$line"
        validate_share "$tag" "$host_path" "$guest_path" "$access" "${extra:-}" ||
            continue
        verify_host_share "$tag" "$host_path" "$guest_path" "$access"
    done < <(share_lines)
}

verify_guest() {
    check 'inside a virtualized guest' inside_guest
    check 'expected agent guest hostname' expected_hostname_matches
    check 'share list present' share_list_present
    check 'share lines valid' verify_share_lines
    check 'findmnt available' command_available findmnt
    check 'awk available' command_available awk
    check 'readlink available' command_available readlink

    local line
    local tag
    local host_path
    local guest_path
    local access
    local extra

    while IFS= read -r line; do
        IFS='|' read -r tag host_path guest_path access extra <<<"$line"
        validate_share "$tag" "$host_path" "$guest_path" "$access" "${extra:-}" ||
            continue
        verify_guest_share "$tag" "$host_path" "$guest_path" "$access"
    done < <(share_lines)
}

case "$mode" in
    host)
        verify_host
        ;;
    guest)
        verify_guest
        ;;
esac

if ((failures > 0)); then
    printf 'virtiofs-user-data-shares verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'virtiofs-user-data-shares verify passed'
