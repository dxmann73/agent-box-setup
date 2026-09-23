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

Host mode checks the Chrome VM libvirt filesystem device.
Guest mode checks the mounted Desktop virtiofs share.

Required host environment:
  CHROME_VM_DOMAIN          libvirt domain name
  DESKTOP_SHARE_HOST_PATH   host Desktop path to share

Optional environment:
  DESKTOP_SHARE_TAG         Default: desktop
  DESKTOP_SHARE_GUEST_PATH  Default: $HOME/Desktop
  DESKTOP_SHARE_XML_PATH    Default: $HOME/vms/share-$DESKTOP_SHARE_TAG.xml
  CHROME_VM_XML_PATH        Default: $HOME/vms/$CHROME_VM_DOMAIN.xml
  CHROME_VM_EXPECTED_HOSTNAME
      Guest hostname guard in --guest mode. Default: $CHROME_VM_DOMAIN or chrome-vm

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

readonly share_tag="${DESKTOP_SHARE_TAG:-desktop}"

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

valid_tag() {
    [[ "$share_tag" =~ ^[A-Za-z0-9_.:-]+$ ]] && [[ "$share_tag" != *'/'* ]]
}

required_host_environment_present() {
    [[ -n "${CHROME_VM_DOMAIN:-}" ]] || return 1
    [[ -n "${DESKTOP_SHARE_HOST_PATH:-}" ]]
}

valid_host_environment() {
    [[ "$CHROME_VM_DOMAIN" =~ ^[A-Za-z0-9][A-Za-z0-9_.:-]*$ ]] || return 1
    [[ "$DESKTOP_SHARE_HOST_PATH" == /* ]] || return 1
    valid_tag
}

domain_exists() {
    virsh -c qemu:///system dominfo "$CHROME_VM_DOMAIN" >/dev/null 2>&1
}

domain_has_memfd_shared() {
    local xml

    xml="$(virsh -c qemu:///system dumpxml --inactive "$CHROME_VM_DOMAIN")" || return 1
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

xml_has_desktop_share() {
    local -r xml="$1"

    python3 -c '
import os
import sys
import xml.etree.ElementTree as ET

root = ET.fromstring(sys.stdin.read())
tag = os.environ["DESKTOP_SHARE_TAG"]
source_path = os.environ["DESKTOP_SHARE_HOST_PATH"]

filesystems = [root] if root.tag == "filesystem" else root.findall("./devices/filesystem")

for fs in filesystems:
    driver = fs.find("driver")
    source = fs.find("source")
    target = fs.find("target")
    if target is None or target.get("dir") != tag:
        continue
    checks = [
        fs.get("type") == "mount",
        fs.get("accessmode") == "passthrough",
        driver is not None and driver.get("type") == "virtiofs",
        source is not None and source.get("dir") == source_path,
        fs.find("readonly") is None,
    ]
    sys.exit(0 if all(checks) else 1)
sys.exit(1)
' <<<"$xml"
}

inactive_domain_has_share() {
    local xml

    xml="$(virsh -c qemu:///system dumpxml --inactive "$CHROME_VM_DOMAIN")" || return 1
    xml_has_desktop_share "$xml"
}

live_domain_has_share_when_running() {
    local state
    local xml

    state="$(virsh -c qemu:///system domstate "$CHROME_VM_DOMAIN")" || return 1
    [[ "$state" == running ]] || return 0
    xml="$(virsh -c qemu:///system dumpxml "$CHROME_VM_DOMAIN")" || return 1
    xml_has_desktop_share "$xml"
}

filesystem_xml_ready() {
    [[ -r "$DESKTOP_SHARE_XML_PATH" ]] || return 1
    xml_has_desktop_share "$(cat "$DESKTOP_SHARE_XML_PATH")"
}

saved_domain_xml_ready() {
    [[ -r "$CHROME_VM_XML_PATH" ]] || return 1
    xml_has_desktop_share "$(cat "$CHROME_VM_XML_PATH")"
}

host_source_narrow() {
    local resolved_source
    local resolved_home

    [[ -d "$DESKTOP_SHARE_HOST_PATH" ]] || return 1
    resolved_source="$(readlink -f -- "$DESKTOP_SHARE_HOST_PATH")" || return 1
    resolved_home="$(readlink -f -- "$HOME")" || return 1
    [[ "$resolved_source" != "$resolved_home" ]] || return 1
    [[ "$resolved_source" == */Desktop ]]
}

inside_guest() {
    systemd-detect-virt --vm --quiet
}

expected_hostname_matches() {
    local expected_hostname="${CHROME_VM_EXPECTED_HOSTNAME:-${CHROME_VM_DOMAIN:-chrome-vm}}"

    [[ "$(hostname)" == "$expected_hostname" ]]
}

guest_path_absolute() {
    [[ "$DESKTOP_SHARE_GUEST_PATH" == /* ]]
}

desktop_mount_ready() {
    local line
    local fstype
    local source
    local options

    line="$(findmnt -rn --target "$DESKTOP_SHARE_GUEST_PATH" --output FSTYPE,SOURCE,OPTIONS)" ||
        return 1
    read -r fstype source options <<<"$line"
    [[ "$fstype" == virtiofs ]] || return 1
    [[ "$source" == "$share_tag" ]] || return 1
    [[ ",${options}," == *,rw,* ]]
}

fstab_line_present() {
    awk -v tag="$share_tag" -v guest_path="$DESKTOP_SHARE_GUEST_PATH" '
        $1 == tag && $2 == guest_path && $3 == "virtiofs" && $4 ~ /(^|,)rw(,|$)/ && $4 ~ /(^|,)nofail(,|$)/ {
            found = 1
        }
        END { exit(found ? 0 : 1) }
    ' /etc/fstab
}

verify_host() {
    required_host_environment_present ||
        die \
            'Missing host environment.' \
            'Export CHROME_VM_DOMAIN and DESKTOP_SHARE_HOST_PATH before running verify.sh --host.'

    readonly DESKTOP_SHARE_TAG="$share_tag"
    readonly DESKTOP_SHARE_XML_PATH="${DESKTOP_SHARE_XML_PATH:-$HOME/vms/share-${share_tag}.xml}"
    readonly CHROME_VM_XML_PATH="${CHROME_VM_XML_PATH:-$HOME/vms/${CHROME_VM_DOMAIN}.xml}"
    export DESKTOP_SHARE_TAG DESKTOP_SHARE_HOST_PATH

    check 'daily host, not guest' bare_metal_host
    check 'environment values valid' valid_host_environment
    check 'virsh available' command_available virsh
    check 'python3 available' command_available python3
    check 'readlink available' command_available readlink
    check 'system libvirt connection' virsh -c qemu:///system list --all
    check 'Chrome VM domain exists' domain_exists
    check 'domain has shared memfd backing for virtiofs' domain_has_memfd_shared
    check 'host source is the narrow Desktop directory' host_source_narrow
    check 'inactive domain XML has the Desktop virtiofs share' inactive_domain_has_share
    check 'live domain XML has the Desktop share when running' live_domain_has_share_when_running
    check 'filesystem device XML saved' filesystem_xml_ready
    check 'saved inactive domain XML includes the share' saved_domain_xml_ready
}

verify_guest() {
    readonly DESKTOP_SHARE_TAG="$share_tag"
    readonly DESKTOP_SHARE_GUEST_PATH="${DESKTOP_SHARE_GUEST_PATH:-$HOME/Desktop}"

    check 'inside a virtualized guest' inside_guest
    check 'expected browser guest hostname' expected_hostname_matches
    check 'share tag valid' valid_tag
    check 'guest Desktop path is absolute' guest_path_absolute
    check 'findmnt available' command_available findmnt
    check 'awk available' command_available awk
    check 'Desktop path is mounted from virtiofs tag read-write' desktop_mount_ready
    check 'fstab persists Desktop virtiofs mount with nofail' fstab_line_present
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
    printf 'virtiofs-desktop-share verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'virtiofs-desktop-share verify passed'
