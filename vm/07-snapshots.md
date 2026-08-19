# 07 – Snapshots, persistence and recovery

The VM runs continuously and its sessions outlive any client (specification §14). It must also be
cheap to throw away and rebuild (specification §3, §13).

## 1. Persistence

- the VM stays powered on; the host client connecting and disconnecting changes nothing
- herdr sessions and agent processes survive a disconnect, see [03-herdr.md](03-herdr.md)
- host suspend/resume with a running VM is worth re-testing explicitly, see
  [`../host/01-hardware-validation.md`](../host/01-hardware-validation.md)

## 2. Snapshots

Take a VMware snapshot at the points where recovery is actually useful:

| Snapshot | When |
| --- | --- |
| `clean-guest` | after [01-bootstrap.md](01-bootstrap.md), before any toolchain |
| `toolchain` | after [02-dev-and-agents.md](02-dev-and-agents.md) passes verification |
| `pre-experiment` | before anything invasive an agent is about to attempt |

Delete `pre-experiment` snapshots once the experiment is settled; long snapshot chains cost
performance and disk.

## 3. Backup

The VM disk images under `~/vms/` are backed up from the host, see
[`../host/03-system-config.md`](../host/03-system-config.md). Back up a powered-off or snapshotted
VM, not a running one.

What actually has to survive a lost VM:

- pushed git branches — anything unpushed in `~/projects` is at risk
- this repo's configuration, which is the source of truth for skills, agent config and herdr
  configuration (specification §9)

Everything else should be reproducible by rebuilding.

## 4. Rebuild test

The reproducibility claim is only real if it has been executed:

```text
fresh Ubuntu VM → bootstrap → toolchain → agents → herdr → Playwright → agent-config repo → ready
```

Run it end to end from a `clean-guest` snapshot periodically. Prefer deterministic scripts over
asking an agent to reproduce machine state by hand.

## 5. Checklist

- [ ] VM runs continuously; disconnecting the client kills nothing
- [ ] named snapshots exist for clean guest and working toolchain
- [ ] VM images included in host backups
- [ ] no unpushed work relied upon as storage
- [ ] rebuild from `clean-guest` executed at least once and timed
