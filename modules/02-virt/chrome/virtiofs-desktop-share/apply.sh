#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C
export LIBVIRT_DEFAULT_URI="${LIBVIRT_DEFAULT_URI:-qemu:///system}"

trap 'printf "ERROR: virtiofs-desktop-share apply failed at line %s\n" "$LINENO" >&2' ERR

mode=""
dry_run=0

usage() {
    cat <<'USAGE'
Usage: ./apply.sh --host [--dry-run]
       ./apply.sh --guest

Host mode attaches the Desktop virtiofs device to the Chrome VM domain.
Guest mode mounts the desktop tag on the guest Desktop and persists it in fstab.

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
  DESKTOP_SHARE_ALLOW_NONEMPTY
      Set to 1 to mount over a non-empty local guest Desktop.

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

readonly share_tag="${DESKTOP_SHARE_TAG:-desktop}"
valid_tag "$share_tag" || die "Invalid DESKTOP_SHARE_TAG: ${share_tag}"

domain_xml_has_share() {
    local -r xml="$1"
    python3 -c '
import os
import sys
import xml.etree.ElementTree as ET

root = ET.fromstring(sys.stdin.read())
tag = os.environ["DESKTOP_SHARE_TAG"]
source_path = os.environ["DESKTOP_SHARE_HOST_PATH"]

for fs in root.findall("./devices/filesystem"):
    driver = fs.find("driver")
    source = fs.find("source")
    target = fs.find("target")
    if target is None or target.get("dir") != tag:
        continue
    ok = (
        fs.get("type") == "mount"
        and fs.get("accessmode") == "passthrough"
        and driver is not None
        and driver.get("type") == "virtiofs"
        and source is not None
        and source.get("dir") == source_path
        and fs.find("readonly") is None
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
tag = os.environ["DESKTOP_SHARE_TAG"]

for target in root.findall("./devices/filesystem/target"):
    if target.get("dir") == tag:
        sys.exit(0)
sys.exit(1)
' <<<"$xml"
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

write_filesystem_xml() {
    local -r destination="$1"

    python3 - "$destination" <<'PY'
import os
import sys
import xml.etree.ElementTree as ET

destination = sys.argv[1]
fs = ET.Element("filesystem", {"type": "mount", "accessmode": "passthrough"})
ET.SubElement(fs, "driver", {"type": "virtiofs"})
ET.SubElement(fs, "source", {"dir": os.environ["DESKTOP_SHARE_HOST_PATH"]})
ET.SubElement(fs, "target", {"dir": os.environ["DESKTOP_SHARE_TAG"]})
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

apply_host() {
    [[ $dry_run -eq 0 || $mode == host ]] || die '--dry-run is only valid with --host.'
    [[ $EUID -ne 0 ]] || die 'Run as the desktop user, not as root.'
    if systemd-detect-virt --quiet; then
        die "virtiofs-desktop-share --host applies to daily hosts only. systemd-detect-virt reports $(systemd-detect-virt)."
    fi

    for variable in CHROME_VM_DOMAIN DESKTOP_SHARE_HOST_PATH; do
        [[ -n "${!variable:-}" ]] || die "Missing required environment variable: ${variable}"
    done

    [[ "$CHROME_VM_DOMAIN" =~ ^[A-Za-z0-9][A-Za-z0-9_.:-]*$ ]] ||
        die "Invalid CHROME_VM_DOMAIN: ${CHROME_VM_DOMAIN}"
    [[ "$DESKTOP_SHARE_HOST_PATH" == /* ]] ||
        die "DESKTOP_SHARE_HOST_PATH must be absolute: ${DESKTOP_SHARE_HOST_PATH}"
    [[ -d "$DESKTOP_SHARE_HOST_PATH" ]] ||
        die "DESKTOP_SHARE_HOST_PATH is not a directory: ${DESKTOP_SHARE_HOST_PATH}"
    [[ "$(readlink -f -- "$DESKTOP_SHARE_HOST_PATH")" != "$(readlink -f -- "$HOME")" ]] ||
        die 'Refusing to share the whole home directory.'

    require_command python3
    require_command virsh
    require_command readlink
    require_command mkdir

    local xml_path="${DESKTOP_SHARE_XML_PATH:-$HOME/vms/share-${share_tag}.xml}"
    local domain_xml_path="${CHROME_VM_XML_PATH:-$HOME/vms/${CHROME_VM_DOMAIN}.xml}"
    local inactive_xml
    local live_xml
    local state

    export DESKTOP_SHARE_TAG DESKTOP_SHARE_HOST_PATH

    inactive_xml="$(virsh -c qemu:///system dumpxml --inactive "$CHROME_VM_DOMAIN")" ||
        die "Domain not found: ${CHROME_VM_DOMAIN}"
    domain_xml_has_memfd_shared "$inactive_xml" ||
        die "Domain lacks shared memfd memory backing required by virtiofs: ${CHROME_VM_DOMAIN}"

    if ((dry_run)); then
        write_filesystem_xml -
        return 0
    fi

    mkdir -p "$(dirname -- "$xml_path")" "$(dirname -- "$domain_xml_path")"
    write_filesystem_xml "$xml_path"

    set +e
    domain_xml_has_share "$inactive_xml"
    local -r share_status=$?
    set -e
    if [[ $share_status -eq 0 ]]; then
        printf 'desktop share already attached in inactive domain XML\n'
    elif [[ $share_status -eq 2 ]] || domain_xml_has_tag "$inactive_xml"; then
        die "Domain already has a filesystem target named ${share_tag}, but it does not match this module."
    else
        virsh -c qemu:///system attach-device "$CHROME_VM_DOMAIN" "$xml_path" --config
    fi

    state="$(virsh -c qemu:///system domstate "$CHROME_VM_DOMAIN")"
    if [[ "$state" == running ]]; then
        live_xml="$(virsh -c qemu:///system dumpxml "$CHROME_VM_DOMAIN")"
        set +e
        domain_xml_has_share "$live_xml"
        local -r live_status=$?
        set -e
        if [[ $live_status -eq 0 ]]; then
            printf 'desktop share already attached in live domain XML\n'
        elif [[ $live_status -eq 2 ]] || domain_xml_has_tag "$live_xml"; then
            die "Live domain already has a filesystem target named ${share_tag}, but it does not match this module."
        else
            virsh -c qemu:///system attach-device "$CHROME_VM_DOMAIN" "$xml_path" --live
        fi
    fi

    virsh -c qemu:///system dumpxml --inactive "$CHROME_VM_DOMAIN" >"$domain_xml_path"
    printf 'virtiofs desktop share attached to %s with tag %s\n' "$CHROME_VM_DOMAIN" "$share_tag"
}

directory_empty_or_mountpoint() {
    local -r path="$1"

    mountpoint -q "$path" && return 0
    [[ ! -e "$path" ]] && return 0
    [[ -d "$path" ]] || return 1
    [[ -z "$(find "$path" -mindepth 1 -maxdepth 1 -print -quit)" ]]
}

fstab_line_present() {
    local -r tag="$1"
    local -r guest_path="$2"

    awk -v tag="$tag" -v guest_path="$guest_path" '
        $1 == tag && $2 == guest_path && $3 == "virtiofs" && $4 ~ /(^|,)rw(,|$)/ && $4 ~ /(^|,)nofail(,|$)/ {
            found = 1
        }
        END { exit(found ? 0 : 1) }
    ' /etc/fstab
}

apply_guest() {
    [[ $dry_run -eq 0 ]] || die '--dry-run is only valid with --host.'
    [[ $EUID -ne 0 ]] || die 'Run as the desktop user, not as root.'
    systemd-detect-virt --vm --quiet || die 'This module applies inside a guest VM only.'

    require_command awk
    require_command find
    require_command findmnt
    require_command mountpoint
    require_command sudo
    require_command systemd-detect-virt

    sudo -n true || die 'Passwordless sudo is required before this module runs.'

    local expected_hostname="${CHROME_VM_EXPECTED_HOSTNAME:-${CHROME_VM_DOMAIN:-chrome-vm}}"
    [[ "$(hostname)" == "$expected_hostname" ]] ||
        die "hostname is $(hostname); expected ${expected_hostname}"

    local guest_path="${DESKTOP_SHARE_GUEST_PATH:-$HOME/Desktop}"
    [[ "$guest_path" == /* ]] || die "DESKTOP_SHARE_GUEST_PATH must be absolute: ${guest_path}"

    if [[ "${DESKTOP_SHARE_ALLOW_NONEMPTY:-0}" != 1 ]] &&
        ! directory_empty_or_mountpoint "$guest_path"; then
        die \
            "Refusing to mount over non-empty guest path: ${guest_path}" \
            'Move existing files aside or set DESKTOP_SHARE_ALLOW_NONEMPTY=1 after review.'
    fi

    mkdir -p "$guest_path"
    if ! mountpoint -q "$guest_path"; then
        sudo mount -t virtiofs "$share_tag" "$guest_path"
    fi

    if ! fstab_line_present "$share_tag" "$guest_path"; then
        local tmp
        tmp="$(mktemp)"
        awk -v tag="$share_tag" -v guest_path="$guest_path" '
            !($1 == tag || ($2 == guest_path && $3 == "virtiofs")) { print }
        ' /etc/fstab >"$tmp"
        printf '%s\t%s\tvirtiofs\trw,nofail\t0\t0\n' "$share_tag" "$guest_path" >>"$tmp"
        sudo install -m 0644 "$tmp" /etc/fstab
        rm -f "$tmp"
    fi

    printf 'virtiofs desktop share mounted at %s with tag %s\n' "$guest_path" "$share_tag"
}

case "$mode" in
    host)
        apply_host
        ;;
    guest)
        apply_guest
        ;;
esac
