#!/usr/bin/env bash
# Inspect one libvirt rollback snapshot without changing guest or snapshot state.
set -Eeuo pipefail
export LC_ALL=C
export LIBVIRT_DEFAULT_URI="${LIBVIRT_DEFAULT_URI:-qemu:///system}"

domain=""
snapshot_name=""
mode=""
require_current=false
failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh --domain DOMAIN --snapshot SNAPSHOT --mode live|offline
                   [--current]

Inspects an existing libvirt rollback snapshot without modifying it. --mode
checks the state saved in the snapshot, not the domain's current state.

Options:
  --domain DOMAIN       Existing libvirt domain
  --snapshot SNAPSHOT   Existing snapshot name
  --mode MODE           Required: live or offline
  --current             Also require SNAPSHOT to be the current snapshot
  -h, --help            Show this help
USAGE
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
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

valid_domain_name() {
    [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9_.:-]*$ ]]
}

valid_snapshot_name() {
    [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]
}

snapshot_exists() {
    virsh -c qemu:///system snapshot-info "$domain" "$snapshot_name" >/dev/null 2>&1
}

snapshot_xml_matches() {
    local snapshot_xml

    snapshot_xml="$(virsh -c qemu:///system snapshot-dumpxml "$domain" "$snapshot_name")" || return 1
    python3 -c '
import sys
import xml.etree.ElementTree as ET

root = ET.fromstring(sys.stdin.read())
expected_domain, expected_snapshot, expected_state = sys.argv[1:]
actual_state = root.findtext("state")
expected_state = "running" if expected_state == "live" else "shutoff"
checks = [
    root.findtext("name") == expected_snapshot,
    root.findtext("./domain/name") == expected_domain,
    actual_state == expected_state,
]
sys.exit(0 if all(checks) else 1)
' "$domain" "$snapshot_name" "$mode" <<<"$snapshot_xml"
}

snapshot_is_current() {
    [[ "$(virsh -c qemu:///system snapshot-current "$domain" --name)" == "$snapshot_name" ]]
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --domain)
            [[ $# -ge 2 ]] || die '--domain requires a value'
            domain="$2"
            shift 2
            ;;
        --snapshot)
            [[ $# -ge 2 ]] || die '--snapshot requires a value'
            snapshot_name="$2"
            shift 2
            ;;
        --mode)
            [[ $# -ge 2 ]] || die '--mode requires a value'
            mode="$2"
            shift 2
            ;;
        --current)
            require_current=true
            shift
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
[[ -n "$snapshot_name" ]] || die '--snapshot is required'
[[ "$mode" == live || "$mode" == offline ]] || die '--mode must be live or offline'
valid_domain_name "$domain" || die "invalid domain name: $domain"
valid_snapshot_name "$snapshot_name" || die "invalid snapshot name: $snapshot_name"
command -v virsh >/dev/null 2>&1 || die 'virsh is required'
command -v python3 >/dev/null 2>&1 || die 'python3 is required'
! systemd-detect-virt --quiet || die 'run this on the daily host, not inside a guest'
virsh -c qemu:///system dominfo "$domain" >/dev/null 2>&1 || die "domain does not exist: $domain"

check 'snapshot exists' snapshot_exists
check "snapshot saves expected $mode state and identity" snapshot_xml_matches
if [[ "$require_current" == true ]]; then
    check 'snapshot is current' snapshot_is_current
fi

if ((failures > 0)); then
    printf 'vm-snapshots verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf 'vm-snapshots verify passed\n'
