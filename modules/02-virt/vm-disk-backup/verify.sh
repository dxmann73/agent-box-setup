#!/usr/bin/env bash
# Inspect one vm-disk-backup set without modifying the set or guest.
set -Eeuo pipefail
export LC_ALL=C

domain=''
backup_dir=''
mode=''
failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh --domain DOMAIN --backup-dir DIRECTORY --mode live|offline

Checks the saved manifest, inactive domain XML, qcow2 consistency, and SHA256
checksums for one vm-disk-backup set. This never changes the guest or backup.

Options:
  --domain DOMAIN          Domain recorded in the set
  --backup-dir DIRECTORY   Exact timestamped backup-set directory
  --mode MODE              Required: live or offline
  -h, --help               Show this help
USAGE
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 2
}

valid_domain_name() {
    [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9_.:-]*$ ]]
}

check() {
    local label="$1"
    shift
    if "$@"; then
        printf 'ok - %s\n' "$label"
    else
        printf 'not ok - %s\n' "$label" >&2
        failures=$((failures + 1))
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --domain | --backup-dir | --mode)
            [[ $# -ge 2 ]] || die "$1 requires a value"
            case "$1" in
                --domain) domain="$2" ;;
                --backup-dir) backup_dir="$2" ;;
                --mode) mode="$2" ;;
            esac
            shift 2
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            die "unknown argument: $1"
            ;;
    esac
done

[[ -n "$domain" ]] || die '--domain is required'
[[ -n "$backup_dir" ]] || die '--backup-dir is required'
[[ "$mode" == live || "$mode" == offline ]] || die '--mode must be live or offline'
valid_domain_name "$domain" || die "invalid domain name: $domain"
[[ "$backup_dir" = /* ]] || die '--backup-dir must be an absolute path'
command -v qemu-img >/dev/null 2>&1 || die 'qemu-img is required'
command -v sha256sum >/dev/null 2>&1 || die 'sha256sum is required'
command -v python3 >/dev/null 2>&1 || die 'python3 is required'

readonly disk="$backup_dir/disk-vda.qcow2"
readonly domain_xml="$backup_dir/domain.xml"
readonly backup_info="$backup_dir/backup-info"
readonly backup_xml="$backup_dir/backup.xml"
readonly sums="$backup_dir/SHA256SUMS"

manifest_matches() {
    [[ "$(awk -F= '$1 == "domain" { print $2; exit }' "$backup_info")" == "$domain" ]] || return 1
    [[ "$(awk -F= '$1 == "mode" { print $2; exit }' "$backup_info")" == "$mode" ]]
}

xml_matches_domain() {
    python3 - "$domain" "$domain_xml" <<'PY'
import sys
import xml.etree.ElementTree as ET

expected, path = sys.argv[1:]
root = ET.parse(path).getroot()
sys.exit(0 if root.findtext('name') == expected else 1)
PY
}

live_request_present() {
    [[ -r "$backup_xml" ]] || return 1
    python3 - "$backup_xml" <<'PY'
import sys
import xml.etree.ElementTree as ET

root = ET.parse(sys.argv[1]).getroot()
sys.exit(0 if root.tag == 'domainbackup' and root.get('mode') == 'push' else 1)
PY
}

offline_request_absent() {
    [[ ! -e "$backup_xml" ]]
}

checksums_match() {
    (
        cd -- "$backup_dir"
        sha256sum --check --status SHA256SUMS
    )
}

disk_is_qcow2() {
    [[ "$(qemu-img info --output=json "$disk" | python3 -c 'import json, sys; print(json.load(sys.stdin).get("format", ""))')" == qcow2 ]]
}

check 'backup directory exists' test -d "$backup_dir"
check 'domain XML exists' test -r "$domain_xml"
check 'manifest exists' test -r "$backup_info"
check 'disk image exists' test -r "$disk"
check 'checksum manifest exists' test -r "$sums"
check 'manifest records requested domain and mode' manifest_matches
check 'saved XML records requested domain' xml_matches_domain
check 'disk image is qcow2' disk_is_qcow2
check 'disk image is internally consistent' qemu-img check "$disk"
check 'saved checksums match' checksums_match
if [[ "$mode" == live ]]; then
    check 'live backup request exists and is push mode' live_request_present
else
    check 'offline set has no live backup request' offline_request_absent
fi

if ((failures > 0)); then
    printf 'vm-disk-backup verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf 'vm-disk-backup verify passed\n'
