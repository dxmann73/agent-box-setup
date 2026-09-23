#!/usr/bin/env bash
# Create one explicit rollback snapshot. This never changes an existing snapshot.
set -Eeuo pipefail
export LC_ALL=C
export LIBVIRT_DEFAULT_URI="${LIBVIRT_DEFAULT_URI:-qemu:///system}"

domain=""
snapshot_name=""
mode=""
description="rollback snapshot"
dry_run=false

usage() {
    cat <<'USAGE'
Usage: ./apply.sh --domain DOMAIN --name SNAPSHOT --mode live|offline
                  [--description TEXT] [--dry-run]

Creates one atomic libvirt rollback snapshot. The domain must be running for
--mode live and shut off for --mode offline. Refuses to replace an existing
snapshot with the same name.

Options:
  --domain DOMAIN       Existing libvirt domain
  --name SNAPSHOT       New snapshot name
  --mode MODE           Required: live or offline
  --description TEXT    Snapshot description (default: rollback snapshot)
  --dry-run             Validate prerequisites without creating a snapshot
  -h, --help            Show this help
USAGE
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 2
}

valid_domain_name() {
    [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9_.:-]*$ ]]
}

valid_snapshot_name() {
    [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --domain)
            [[ $# -ge 2 ]] || die '--domain requires a value'
            domain="$2"
            shift 2
            ;;
        --name)
            [[ $# -ge 2 ]] || die '--name requires a value'
            snapshot_name="$2"
            shift 2
            ;;
        --mode)
            [[ $# -ge 2 ]] || die '--mode requires a value'
            mode="$2"
            shift 2
            ;;
        --description)
            [[ $# -ge 2 ]] || die '--description requires a value'
            description="$2"
            shift 2
            ;;
        --dry-run)
            dry_run=true
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
[[ -n "$snapshot_name" ]] || die '--name is required'
[[ "$mode" == live || "$mode" == offline ]] || die '--mode must be live or offline'
valid_domain_name "$domain" || die "invalid domain name: $domain"
valid_snapshot_name "$snapshot_name" || die "invalid snapshot name: $snapshot_name"
[[ -n "$description" ]] || die '--description must not be empty'
command -v virsh >/dev/null 2>&1 || die 'virsh is required'
! systemd-detect-virt --quiet || die 'run this on the daily host, not inside a guest'
virsh -c qemu:///system dominfo "$domain" >/dev/null 2>&1 || die "domain does not exist: $domain"

domain_state="$(virsh -c qemu:///system domstate "$domain")"
if [[ "$mode" == live && "$domain_state" != running ]]; then
    die "--mode live requires a running domain; current state: $domain_state"
fi
if [[ "$mode" == offline && "$domain_state" != 'shut off' ]]; then
    die "--mode offline requires a shut-off domain; current state: $domain_state"
fi

if virsh -c qemu:///system snapshot-info "$domain" "$snapshot_name" >/dev/null 2>&1; then
    die "snapshot already exists and will not be replaced: $domain/$snapshot_name"
fi

if [[ "$dry_run" == true ]]; then
    printf 'Would create %s snapshot %s for %s\n' "$mode" "$snapshot_name" "$domain"
    exit 0
fi

virsh -c qemu:///system snapshot-create-as \
    "$domain" "$snapshot_name" --description "$description" --atomic

printf 'Created %s snapshot %s for %s\n' "$mode" "$snapshot_name" "$domain"
