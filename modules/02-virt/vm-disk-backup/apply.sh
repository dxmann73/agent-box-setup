#!/usr/bin/env bash
# Create one non-overwriting, same-host backup set for a libvirt guest disk.
set -Eeuo pipefail
export LC_ALL=C
export LIBVIRT_DEFAULT_URI="${LIBVIRT_DEFAULT_URI:-qemu:///system}"

domain=''
backup_root=''
label=''
mode=''
prune_weekly=''
dry_run=false

usage() {
    cat <<'USAGE'
Usage: ./apply.sh --domain DOMAIN --destination DIRECTORY --label LABEL
                  --mode live|offline [--prune-weekly COUNT] [--dry-run]

Creates a non-overwriting same-host qcow2 backup set at:
  DIRECTORY/DOMAIN/UTC-TIMESTAMP-LABEL/

live uses libvirt's push backup API and requires DOMAIN to be running.
offline copies the one file-backed disk and requires DOMAIN to be shut off.

Options:
  --domain DOMAIN          Existing libvirt domain; no default
  --destination DIRECTORY  Absolute backup-root directory; no default
  --label LABEL            Human set suffix, for example current-credentialed
  --mode MODE              Required: live or offline
  --prune-weekly COUNT     After success, retain newest COUNT weekly sets only
  --dry-run                Validate and print planned operations without writing
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

valid_label() {
    [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]
}

run_sudo() {
    if [[ -n "${SUDO_ASKPASS:-}" ]]; then
        command sudo -A "$@"
    else
        command sudo "$@"
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --domain | --destination | --label | --mode | --prune-weekly)
            [[ $# -ge 2 ]] || die "$1 requires a value"
            case "$1" in
                --domain) domain="$2" ;;
                --destination) backup_root="$2" ;;
                --label) label="$2" ;;
                --mode) mode="$2" ;;
                --prune-weekly) prune_weekly="$2" ;;
            esac
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
[[ -n "$backup_root" ]] || die '--destination is required'
[[ -n "$label" ]] || die '--label is required'
[[ "$mode" == live || "$mode" == offline ]] || die '--mode must be live or offline'
valid_domain_name "$domain" || die "invalid domain name: $domain"
valid_label "$label" || die "invalid label: $label"
[[ "$backup_root" = /* ]] || die '--destination must be an absolute path'
[[ "$backup_root" != *$'\n'* ]] || die '--destination must not contain a newline'
if [[ -n "$prune_weekly" ]]; then
    [[ "$prune_weekly" =~ ^[1-9][0-9]*$ ]] || die '--prune-weekly must be a positive integer'
fi

command -v virsh >/dev/null 2>&1 || die 'virsh is required'
command -v qemu-img >/dev/null 2>&1 || die 'qemu-img is required'
command -v sha256sum >/dev/null 2>&1 || die 'sha256sum is required'
command -v setfacl >/dev/null 2>&1 || die 'setfacl is required'
command -v getent >/dev/null 2>&1 || die 'getent is required'
! systemd-detect-virt --quiet || die 'run this on the daily host, not inside a guest'
getent passwd libvirt-qemu >/dev/null || die 'the libvirt-qemu user is required'
virsh -c qemu:///system dominfo "$domain" >/dev/null 2>&1 || die "domain does not exist: $domain"

domain_state="$(virsh -c qemu:///system domstate "$domain")"
if [[ "$mode" == live && "$domain_state" != running ]]; then
    die "--mode live requires a running domain; current state: $domain_state"
fi
if [[ "$mode" == offline && "$domain_state" != 'shut off' ]]; then
    die "--mode offline requires a shut-off domain; current state: $domain_state"
fi

mapfile -t disk_rows < <(virsh -c qemu:///system domblklist "$domain" --details | awk '$1 == "file" && $2 == "disk" { print $3 "|" $4 }')
[[ ${#disk_rows[@]} -eq 1 ]] || die "expected one file-backed VM disk, found: ${#disk_rows[@]}"
disk_target="${disk_rows[0]%%|*}"
source_disk="${disk_rows[0]#*|}"
[[ -n "$disk_target" && -n "$source_disk" ]] || die 'could not determine the guest disk target and source'

virtual_bytes="$(virsh -c qemu:///system domblkinfo "$domain" "$disk_target" | awk '/^Capacity:/ { print $2; exit }')"
[[ "$virtual_bytes" =~ ^[0-9]+$ ]] || die 'could not determine virtual disk capacity'

timestamp="$(date --utc +%Y-%m-%dT%H%M%SZ)"
backup_dir="$backup_root/$domain/${timestamp}-${label}"
work_dir="$backup_root/$domain/.incomplete-${timestamp}-${label}-$$"
backup_disk="$work_dir/disk-vda.qcow2"
domain_xml="$work_dir/domain.xml"
backup_info="$work_dir/backup-info"
backup_xml="$work_dir/backup.xml"

[[ ! -e "$backup_dir" ]] || die "backup directory already exists: $backup_dir"
[[ ! -e "$work_dir" ]] || die "temporary backup directory already exists: $work_dir"

prune_sets() {
    local sets_dir="$backup_root/$domain"
    local entry name set_label
    local -a weekly=()

    [[ -d "$sets_dir" ]] || return 0
    shopt -s nullglob
    for entry in "$sets_dir"/*; do
        [[ -d "$entry" ]] || continue
        name="${entry##*/}"
        [[ "$name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{6}Z-(.+)$ ]] || continue
        set_label="${BASH_REMATCH[1]}"
        [[ "$set_label" == weekly ]] && weekly+=("$entry")
    done
    shopt -u nullglob

    (( ${#weekly[@]} > prune_weekly )) || {
        printf 'Weekly retention: %d set(s), nothing to prune\n' "${#weekly[@]}"
        return 0
    }

    mapfile -t weekly < <(printf '%s\n' "${weekly[@]}" | LC_ALL=C sort)
    local delete_count=$(( ${#weekly[@]} - prune_weekly ))
    for entry in "${weekly[@]:0:delete_count}"; do
        if [[ "$dry_run" == true ]]; then
            printf 'Would delete weekly backup set: %s\n' "$entry"
        else
            run_sudo rm -rf -- "$entry"
            printf 'Deleted weekly backup set: %s\n' "$entry"
        fi
    done
}

if [[ "$dry_run" == true ]]; then
    printf 'Would create %s backup of %s at %s\n' "$mode" "$domain" "$backup_dir"
    printf 'Requires at least %s bytes free in %s before writing.\n' \
        "$((virtual_bytes + 1024 * 1024 * 1024))" "$backup_root"
    [[ -n "$prune_weekly" ]] && prune_sets
    exit 0
fi

parent_dir="$(dirname -- "$backup_root")"
run_sudo setfacl -m u:libvirt-qemu:--x "$HOME"
if [[ "$parent_dir" == "$HOME"/* ]]; then
    run_sudo install -d -o "$USER" -g libvirt-qemu -m 0770 "$parent_dir"
fi
run_sudo install -d -o "$USER" -g libvirt-qemu -m 0770 "$backup_root"
run_sudo install -d -o "$USER" -g libvirt-qemu -m 0770 "$backup_root/$domain"
run_sudo install -d -o "$USER" -g libvirt-qemu -m 0770 "$work_dir"

cleanup_incomplete_set() {
    [[ -d "$work_dir" ]] || return 0
    run_sudo rm -rf -- "$work_dir"
}

trap cleanup_incomplete_set ERR INT TERM

available_bytes="$(df -B1 --output=avail "$backup_root" | awk 'NR == 2 { print $1 }')"
[[ "$available_bytes" =~ ^[0-9]+$ ]] || die "could not determine free space at $backup_root"
required_bytes=$((virtual_bytes + 1024 * 1024 * 1024))
(( available_bytes >= required_bytes )) || die \
    "insufficient free space: need $required_bytes bytes, have $available_bytes bytes"

virsh -c qemu:///system dumpxml --inactive "$domain" > "$domain_xml"
printf 'domain=%s\nmode=%s\ndisk_target=%s\nsource_disk=%s\n' \
    "$domain" "$mode" "$disk_target" "$source_disk" > "$backup_info"

if [[ "$mode" == live ]]; then
    cat > "$backup_xml" <<EOF
<domainbackup mode='push'>
  <disks>
    <disk name='$disk_target' type='file'>
      <target file='$backup_disk'/>
      <driver type='qcow2'/>
    </disk>
  </disks>
</domainbackup>
EOF
    virsh -c qemu:///system backup-begin "$domain" "$backup_xml"
    while true; do
        job_info="$(virsh -c qemu:///system domjobinfo "$domain")"
        printf '%s\n' "$job_info"
        [[ "$job_info" == *'Job type:         None'* ]] && break
        sleep 5
    done
    completed_job="$(virsh -c qemu:///system domjobinfo "$domain" --completed --keep-completed)"
    printf '%s\n' "$completed_job"
    [[ "$completed_job" == *'Job type:         Completed'* ]] || die 'live backup did not complete'
    [[ "$completed_job" == *'Operation:        Backup'* ]] || die 'completed job was not a backup'
else
    run_sudo qemu-img convert -p -O qcow2 "$source_disk" "$backup_disk"
fi

run_sudo qemu-img check "$backup_disk"
run_sudo chown "$USER":libvirt-qemu "$backup_disk"
run_sudo chmod 0640 "$backup_disk"
# Relative names keep the checksums valid after the rename below.
checksum_files=(domain.xml backup-info disk-vda.qcow2)
if [[ "$mode" == live ]]; then checksum_files+=(backup.xml); fi
(cd -- "$work_dir" && sha256sum -- "${checksum_files[@]}" > SHA256SUMS)
sync
mv -- "$work_dir" "$backup_dir"
trap - ERR INT TERM
printf 'Created %s backup: %s\n' "$mode" "$backup_dir"

if [[ -n "$prune_weekly" ]]; then prune_sets; fi
