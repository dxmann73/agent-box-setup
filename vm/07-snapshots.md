# 07 – Snapshots, persistence and recovery

The VM runs continuously and its sessions outlive any client (specification §14). It must also be
cheap to throw away and rebuild (specification §3, §13).

## 1. Persistence

- the VM stays powered on; the host client connecting and disconnecting changes nothing
- T3 Code sessions and agent processes survive a disconnect, see [04-t3code.md](04-t3code.md)
- host suspend/resume with a running VM is worth re-testing explicitly, see
  [`../host/01-hardware-validation.md`](../host/01-hardware-validation.md)

## 2. Snapshots

libvirt snapshots of the qcow2 disk. Taken while the VM runs they include memory state, so
reverting lands in a running machine rather than at a boot prompt. This works because the guest
uses BIOS firmware: libvirt restricts internal snapshots on UEFI/pflash domains, which is one of
the reasons [`../host/05-hypervisor.md`](../host/05-hypervisor.md) §5 chooses SeaBIOS.

```bash
virsh snapshot-create-as agent-vm clean-guest --description 'bootstrapped, no toolchain' --atomic
virsh snapshot-list agent-vm --tree
virsh snapshot-revert agent-vm clean-guest
virsh snapshot-delete agent-vm pre-experiment
```

Every `virsh` here assumes `LIBVIRT_DEFAULT_URI=qemu:///system`
([`../host/05-hypervisor.md`](../host/05-hypervisor.md) §3). Without it these commands address the
per-user session daemon and report that the domain does not exist.

Take one at the points where recovery is actually useful:

| Snapshot | When |
| --- | --- |
| `clean-guest` | after [01-bootstrap.md](01-bootstrap.md), before any toolchain |
| `toolchain` | after [02-dev-and-agents.md](02-dev-and-agents.md) passes verification |
| `pre-experiment` | before anything invasive an agent is about to attempt |

Delete `pre-experiment` snapshots once the experiment is settled. Internal snapshots live inside the
qcow2 file: every one of them grows it and long chains cost read performance.

Two things a snapshot does **not** cover:

- host directories shared over virtiofs ([06-shared-folders.md](06-shared-folders.md)) — those are
  host files, and reverting the VM does not undo a write an agent made in a share
- the disk file itself. A snapshot inside `agent-vm.qcow2` dies with `agent-vm.qcow2`; it is an undo
  button, not a backup

## 3. Backup

Two files, both on the host: the disk image in libvirt's pool, and the domain XML that describes
the hardware around it. Back up a powered-off VM, not a running one:

```bash
virsh shutdown agent-vm                                   # wait for it to stop
virsh dumpxml agent-vm > ~/vms/agent-vm.xml               # the definition is not in the disk image
sudo cp --sparse=always /var/lib/libvirt/images/agent-vm.qcow2 /backup/target/
virsh start agent-vm
```

`--sparse=always` matters: the file is provisioned at 200 GiB and is far smaller on disk.

The domain XML is the piece people lose — without it a restored disk image has to be re-attached to
a hand-rebuilt domain. Restoring is `virsh define ~/vms/agent-vm.xml` plus the image back in the
pool. There is no NVRAM file to keep track of, because the guest is BIOS-booted
([`../host/05-hypervisor.md`](../host/05-hypervisor.md) §5).

Both paths are in the host backup set ([`../host/03-system-config.md`](../host/03-system-config.md)).

What actually has to survive a lost VM:

- pushed git branches — anything unpushed in `~/projects` is at risk
- this repo's configuration, which is the source of truth for skills, agent config and T3 Code
  configuration (specification §9)

Everything else should be reproducible by rebuilding.

## 4. Rebuild test

The reproducibility claim is only real if it has been executed:

```text
fresh Ubuntu VM → bootstrap → toolchain → agents → T3 Code → Playwright → agent-config repo → ready
```

Step one, the Kubuntu install, is either hand-driven once or scripted with autoinstall
([`../host/05-hypervisor.md`](../host/05-hypervisor.md) §5). Either way, what makes rebuilds cheap
is keeping its result as a baseline image:

```bash
virsh shutdown agent-vm                                              # wait for it to stop
sudo cp --sparse=always /var/lib/libvirt/images/agent-vm.qcow2 \
                        /var/lib/libvirt/images/baseline-clean-guest.qcow2
virsh dumpxml agent-vm > ~/vms/agent-vm.xml
virsh start agent-vm
```

That baseline is the artifact the chain starts from. To exercise the chain without touching the
working VM, clone it:

```bash
virt-clone --original agent-vm --name agent-vm-rebuild \
  --file /var/lib/libvirt/images/agent-vm-rebuild.qcow2
```

`virt-clone` resets the MAC address and the machine ID, so the clone gets its own DHCP lease. Give
it a different hostname before putting it on the tailnet. Delete it with
`virsh undefine agent-vm-rebuild --remove-all-storage` when the test is done.

Everything after the guest install — toolchain, agents, T3 Code, Playwright, agent config — comes
from this repo and should stay scripted. Prefer deterministic scripts over asking an agent to
reproduce machine state by hand.

## 5. Checklist

- [ ] VM runs continuously; disconnecting the client kills nothing
- [ ] named snapshots exist for clean guest and working toolchain
- [ ] disk image and domain XML both included in host backups
- [ ] a restore has been tried: `virsh define` the XML, image back in the pool, VM boots
- [ ] no unpushed work relied upon as storage
- [ ] baseline image kept, and a rebuild from it executed at least once and timed
