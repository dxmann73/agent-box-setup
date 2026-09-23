# vm-snapshots recipe

Run this on a daily host after the relevant guest has been installed. It manages rollback snapshots
only. Disk-copy recovery is deliberately owned by the following `vm-disk-backup` module.

The profile chooses its guest roles and labels. The command accepts no default domain, so it cannot
silently snapshot a different guest. It also refuses to replace an existing label.

## Choose the snapshot mode

Use `--mode live` only for a running guest whose domain configuration supports live snapshots with
memory state. The agent VM's 2D virtio console is configured for this. Use `--mode offline` for a
shut-off guest. The 3D SPICE-GL Chrome guest uses this mode: its profile must shut it off first.

Take a rollback point after the appropriate acceptance gate, and another immediately before an
invasive experiment. Suggested labels are profile policy, not generic requirements:

- `clean-guest` after a credential-free bootstrap verification;
- `credentialed` after credentials and a proven disk backup; and
- `pre-experiment` before risky work.

Snapshots preserve disk and domain state. Reverting one can remove virtiofs devices or other domain
changes added afterward. Host-backed shares are host state: a revert does not roll back their files.

## Create and verify a snapshot

```bash
cd ~/projects/agent-box-setup/modules/02-virt/vm-snapshots

# Running agent guest, only after its live-snapshot prerequisites are verified.
./apply.sh --domain AGENT_DOMAIN --name clean-guest --mode live \
  --description 'credential-free bootstrap accepted'
./verify.sh --domain AGENT_DOMAIN --snapshot clean-guest --mode live --current

# Shut-off 3D browser guest.
./apply.sh --domain BROWSER_DOMAIN --name clean --mode offline \
  --description 'browser accepted'
./verify.sh --domain BROWSER_DOMAIN --snapshot clean --mode offline --current
```

`--dry-run` validates the domain, mode, and snapshot-name collision without writing a snapshot. The
verifier is read-only and checks the state recorded in the snapshot rather than requiring the guest
to still be in that state.

## Delete and revert deliberately

Inspect the tree before removing anything. Delete children individually before their parent; never
use `virsh snapshot-delete --children` or `--metadata` to force a removal.

```bash
virsh -c qemu:///system snapshot-list DOMAIN --tree
virsh -c qemu:///system snapshot-delete DOMAIN pre-experiment
virsh -c qemu:///system snapshot-revert DOMAIN clean-guest
```

Snapshot revert is a state-changing recovery operation. Confirm the snapshot includes every domain
device that must survive it, and stop work that relies on newer guest state before reverting.

## Boundaries

- This module creates and verifies rollback snapshots; it does not create disk copies, schedule
  backups, prove restores, or delete snapshots automatically.
- A snapshot is same-storage rollback, not protection from host-disk loss, theft, fire, or
  ransomware.
- Keep project work pushed to its remote. Back up host data and shared directories separately.
