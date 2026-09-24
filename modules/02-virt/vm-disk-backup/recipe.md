# vm-disk-backup recipe

Run this on the daily host that owns the guest, after `vm-snapshots`. This is a same-host recovery
copy, not protection from host-disk loss, theft, fire, or ransomware. Keep project work pushed to
its remote.

The deployment selects the guest role, backup root, labels, retention, and schedule. The generic
recipe deliberately has no defaults for the domain or destination, so it cannot back up a different
guest by accident.

## Choose a mode

- `live` keeps a running guest online and uses libvirt's push backup API. The restored guest
  cold-boots; RAM state is not included.
- `offline` requires the guest to be shut off, then converts its sole file-backed disk to qcow2. Use
  this for guests whose profile does not support live backup, including the 3D browser-guest policy
  in the Dave overlay.

Each successful backup creates a non-overwriting set at:

```text
DESTINATION/DOMAIN/UTC-TIMESTAMP-LABEL/
```

The set contains `disk-vda.qcow2`, inactive `domain.xml`, `backup-info`, and `SHA256SUMS`. Live sets
also include the libvirt `backup.xml` request. Before starting, the script requires the virtual disk
capacity plus a 1 GiB reserve; the actual qcow2 file may be sparse, but `du` is not a safe capacity
estimate.

## Create and verify a backup

```bash
cd ~/projects/agent-box-setup/modules/02-virt/vm-disk-backup

# Running agent guest: libvirt push backup.
./apply.sh --domain AGENT_DOMAIN --destination "$HOME/backup/vm" \
  --label current-credentialed --mode live --dry-run
./apply.sh --domain AGENT_DOMAIN --destination "$HOME/backup/vm" \
  --label current-credentialed --mode live

# Shut-off browser guest: offline qcow2 copy.
./apply.sh --domain BROWSER_DOMAIN --destination "$HOME/backup/vm" \
  --label clean --mode offline --dry-run
./apply.sh --domain BROWSER_DOMAIN --destination "$HOME/backup/vm" \
  --label clean --mode offline

# Replace BACKUP_SET with the directory printed by apply.sh.
./verify.sh --domain AGENT_DOMAIN --backup-dir BACKUP_SET --mode live
```

`apply.sh` sets narrow `libvirt-qemu` access to the backup tree. It uses `sudo`; set `SUDO_ASKPASS`
to a GUI askpass program when no terminal is available. It rejects domains with anything other than
one file-backed disk.

## Retention is explicit

No backup is deleted by default. After a known-good backup has been verified, use
`--prune-weekly COUNT` together with a new or existing `--label weekly` to retain the newest `COUNT`
timestamped weekly sets for that exact domain. It never removes other labels, and it refuses a count
below one. Review `--dry-run` output before pruning.

```bash
./apply.sh --domain BROWSER_DOMAIN --destination "$HOME/backup/vm" \
  --label weekly --mode offline --prune-weekly 4 --dry-run
```

The Dave overlay currently schedules the browser guest weekly with four retained sets and keeps
`clean` sets indefinitely. That deployment policy is not a generic default.

## Recovery proof

Do not define the saved XML over the primary. Boot a new domain from a writable qcow2 overlay of
`disk-vda.qcow2`, with a new UUID and MAC; remove host filesystem shares and keep networking down
until copied service identity is disabled. Record the disposable-overlay acceptance in the
deployment overlay.

## Simplification candidate

The legacy agent live-backup script and Dave-only Chrome offline wrapper duplicate this module's two
modes. After cutover has proved this recipe on both roles, consider replacing those wrappers with
small role-specific commands that only supply profile values and retention policy. Do not remove
them before that migration is explicitly approved and verified.
