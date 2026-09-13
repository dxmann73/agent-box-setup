#!/usr/bin/env bash
# Create a full, same-host, live disk backup of the agent VM.
set -Eeuo pipefail

readonly default_domain='xmg-evo-agent-vm'
readonly default_backup_root="$HOME/backup/vm"
readonly label_pattern='^[A-Za-z0-9][A-Za-z0-9._-]*$'

domain="$default_domain"
backup_root="$default_backup_root"
label=''
dry_run=false

usage() {
    cat <<'EOF'
Usage: backup-agent-vm.sh --label NAME [--domain NAME] [--destination DIRECTORY] [--dry-run]

Creates a timestamped, full live backup with libvirt's push backup API. The
default tree is ~/backup/vm/<domain>/<UTC-timestamp>-<label>/. This is a
same-host recovery copy, not an off-host backup.

--domain names the running libvirt guest. --label is the human suffix
(current-credentialed). Timestamps are UTC YYYY-MM-DDTHHMMSSZ.
EOF
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
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
        --domain)
            [[ $# -ge 2 ]] || die '--domain requires a value'
            domain="$2"
            shift 2
            ;;
        --destination)
            [[ $# -ge 2 ]] || die '--destination requires a value'
            backup_root="$2"
            shift 2
            ;;
        --label)
            [[ $# -ge 2 ]] || die '--label requires a value'
            label="$2"
            shift 2
            ;;
        --dry-run)
            dry_run=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            die "unknown option: $1"
            ;;
    esac
done

command -v virsh >/dev/null || die 'virsh is required'
command -v qemu-img >/dev/null || die 'qemu-img is required'
command -v setfacl >/dev/null || die 'setfacl is required'
getent passwd libvirt-qemu >/dev/null || die 'the libvirt-qemu user is required'

[[ -n "$label" ]] || die '--label is required'
[[ "$label" =~ $label_pattern ]] || die "invalid --label: $label"
[[ "$backup_root" = /* ]] || die '--destination must be an absolute path'
[[ "$(virsh domstate "$domain")" == running ]] || die "domain is not running: $domain"

disk_count="$(virsh domblklist "$domain" --details | awk '$1 == "file" && $2 == "disk" { count++ } END { print count + 0 }')"
[[ "$disk_count" == 1 ]] || die "expected one file-backed VM disk, found: $disk_count"
source_disk="$(virsh domblklist "$domain" --details | awk '$1 == "file" && $2 == "disk" { source = $4 } END { print source }')"
[[ -n "$source_disk" ]] || die 'could not determine the VM disk source'

timestamp="$(date --utc +%Y-%m-%dT%H%M%SZ)"
backup_dir="$backup_root/$domain/${timestamp}-${label}"
backup_disk="$backup_dir/disk-vda.qcow2"
backup_xml="$backup_dir/backup.xml"
domain_xml="$backup_dir/domain.xml"

if [[ -e "$backup_dir" ]]; then
    die "backup directory already exists: $backup_dir"
fi

if [[ "$dry_run" == true ]]; then
    printf 'Would create a live backup of %s at %s\n' "$domain" "$backup_dir"
    printf "%s\n" 'The VM remains running. The destination needs about the VM disk’s used space.'
    exit 0
fi

# QEMU writes the backup target as libvirt-qemu. Give that user traversal of
# the private home directory and access only to this dedicated backup tree.
run_sudo setfacl -m u:libvirt-qemu:--x "$HOME"
parent_dir="$(dirname "$backup_root")"
if [[ "$parent_dir" == "$HOME"/* ]]; then
    run_sudo install -d -o "$USER" -g libvirt-qemu -m 0770 "$parent_dir"
    run_sudo chown "$USER":libvirt-qemu "$parent_dir"
    run_sudo chmod 0770 "$parent_dir"
fi
run_sudo install -d -o "$USER" -g libvirt-qemu -m 0770 "$backup_root"
run_sudo install -d -o "$USER" -g libvirt-qemu -m 0770 "$backup_root/$domain"
run_sudo install -d -o "$USER" -g libvirt-qemu -m 0770 "$backup_dir"

virtual_bytes="$(virsh domblkinfo "$domain" vda | awk '/^Capacity:/ { print $2 }')"
[[ "$virtual_bytes" =~ ^[0-9]+$ ]] || die 'could not determine virtual disk size'
available_bytes="$(df -B1 --output=avail "$backup_root" | tail -n 1 | tr -d '[:space:]')"
required_bytes=$((virtual_bytes + 1024 * 1024 * 1024))
(( available_bytes >= required_bytes )) || die \
    "insufficient free space: need $required_bytes bytes, have $available_bytes bytes"

virsh dumpxml "$domain" > "$domain_xml"

cat > "$backup_xml" <<EOF
<domainbackup mode='push'>
  <disks>
    <disk name='vda' type='file'>
      <target file='$backup_disk'/>
      <driver type='qcow2'/>
    </disk>
  </disks>
</domainbackup>
EOF

virsh backup-begin "$domain" "$backup_xml"

while true; do
    job_info="$(virsh domjobinfo "$domain")"
    printf '%s\n' "$job_info"
    if [[ "$job_info" == *'Job type:         None'* ]]; then
        break
    fi
    sleep 5
done

completed_job="$(virsh domjobinfo "$domain" --completed --keep-completed)"
printf '%s\n' "$completed_job"
[[ "$completed_job" == *'Job type:         Completed'* ]] || die 'live backup did not complete'
[[ "$completed_job" == *'Operation:        Backup'* ]] || die 'completed job was not a backup'

run_sudo qemu-img check "$backup_disk"
run_sudo chown "$USER":libvirt-qemu "$backup_disk"
run_sudo chmod 0640 "$backup_disk"
sha256sum "$domain_xml" "$backup_disk" > "$backup_dir/SHA256SUMS"
sync

printf 'Live backup complete: %s\n' "$backup_dir"
