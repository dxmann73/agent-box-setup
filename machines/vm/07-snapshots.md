# 07 – Snapshots, persistence and recovery

The VM runs continuously and its sessions outlive any client (specification §14). It must also be
cheap to throw away and rebuild (specification §3, §13).

## 1. Persistence

- the VM stays powered on; the host client connecting and disconnecting changes nothing
- BB sessions and agent processes survive a disconnect, see [04-bb.md](04-bb.md)
- host suspend/resume with a running VM is worth re-testing explicitly, see
  [`../host/01-hardware-validation.md`](../host/01-hardware-validation.md)

## 2. Snapshots

libvirt snapshots of the qcow2 disk. Taken while the VM runs they include memory state, so reverting
lands in a running machine rather than at a boot prompt. This works because the guest uses BIOS
firmware: libvirt restricts internal snapshots on UEFI/pflash domains, which is one of the reasons
[`../host/05-hypervisor.md`](../host/05-hypervisor.md) §5 chooses SeaBIOS.

BIOS firmware is necessary but not sufficient. Saving memory state goes through QEMU's migration
path, and a device that cannot migrate blocks the whole snapshot:

```text
error: Requested operation is not valid: cannot migrate domain: virgl is not yet migratable
```

That is virgl, the 3D acceleration from `--graphics spice,gl.enable=yes --video virtio,accel3d=yes`.
A guest configured that way takes no live snapshots at all. The domain here therefore runs with
`<gl enable='no'/>` and `accel3d='no'` ([`../host/05-hypervisor.md`](../host/05-hypervisor.md) §5):
the console is a headless agent VM inspected occasionally, so snapshots are worth more than GPU
acceleration in it. Check before assuming a snapshot will work:

```bash
virsh dumpxml xmg-evo-agent-vm | grep -E "<gl |accel3d"
```

```bash
virsh snapshot-create-as xmg-evo-agent-vm clean-guest --description 'bootstrapped, no toolchain' --atomic
virsh snapshot-list xmg-evo-agent-vm --tree
virsh snapshot-revert xmg-evo-agent-vm clean-guest
virsh snapshot-delete xmg-evo-agent-vm pre-experiment
```

Every `virsh` here assumes `LIBVIRT_DEFAULT_URI=qemu:///system`
([`../host/05-hypervisor.md`](../host/05-hypervisor.md) §3). Without it these commands address the
per-user session daemon and report that the domain does not exist.

Take one at the points where recovery is actually useful:

| Snapshot         | When                                                                   |
| ---------------- | ---------------------------------------------------------------------- |
| `clean-guest`    | after [01-bootstrap.md](01-bootstrap.md) §7, **before** credentials    |
| `toolchain`      | after [02-dev-and-agents.md](02-dev-and-agents.md) passes verification |
| `pre-experiment` | before anything invasive an agent is about to attempt                  |

`clean-guest` is taken **before** [01-bootstrap.md](01-bootstrap.md)'s credentials section, not
after it. A snapshot lives inside the qcow2 and captures whatever is on disk, so one taken after
[05-credentials.md](05-credentials.md) carries the VM's SSH private key, its `gh` token and
`~/.bash_secrets` into every copy of that image. Reverting to a credential-free snapshot costs one
re-run of `vm/05`; a snapshot full of live tokens costs a rotation.

Delete `pre-experiment` snapshots once the experiment is settled. Internal snapshots live inside the
qcow2 file: every one of them grows it and long chains cost read performance.

Two things a snapshot does **not** cover:

- host directories shared over virtiofs ([06-shared-folders.md](06-shared-folders.md)) — those are
  host files, and reverting the VM does not undo a write an agent made in a share
- the disk file itself. A snapshot inside `xmg-evo-agent-vm.qcow2` dies with
  `xmg-evo-agent-vm.qcow2`; it is an undo button, not a backup

## 3. Backup

Two files, both on the host: the disk image in libvirt's pool, and the domain XML that describes the
hardware around it. Back up a powered-off VM, not a running one:

```bash
virsh shutdown xmg-evo-agent-vm                                   # wait for it to stop
virsh dumpxml xmg-evo-agent-vm > ~/vms/xmg-evo-agent-vm.xml               # the definition is not in the disk image
sudo cp --sparse=always /var/lib/libvirt/images/xmg-evo-agent-vm.qcow2 /backup/target/
virsh start xmg-evo-agent-vm
```

`--sparse=always` matters: the file is provisioned at 200 GiB and is far smaller on disk.

The domain XML is the piece people lose — without it a restored disk image has to be re-attached to
a hand-rebuilt domain. Restoring is `virsh define ~/vms/xmg-evo-agent-vm.xml` plus the image back in
the pool. There is no NVRAM file to keep track of, because the guest is BIOS-booted
([`../host/05-hypervisor.md`](../host/05-hypervisor.md) §5).

Both paths are in the host backup set
([`../host/03-system-config.md`](../host/03-system-config.md)).

What actually has to survive a lost VM:

- pushed git branches — anything unpushed in `~/projects` is at risk
- this repo's configuration, which is the source of truth for skills, agent config and BB
  configuration (specification §9)

Everything else should be reproducible by rebuilding.

## 4. Rebuild test

The reproducibility claim is only real if it has been executed:

```text
fresh Ubuntu VM → bootstrap → toolchain → agents → BB → Playwright → agent-config repo → ready
```

Step one, the Kubuntu install, is either hand-driven once or scripted with autoinstall
([`../host/05-hypervisor.md`](../host/05-hypervisor.md) §5). Either way, what makes rebuilds cheap
is keeping its result as a baseline image:

```bash
virsh shutdown xmg-evo-agent-vm                                              # wait for it to stop
sudo cp --sparse=always /var/lib/libvirt/images/xmg-evo-agent-vm.qcow2 \
                        /var/lib/libvirt/images/baseline-clean-guest.qcow2
virsh dumpxml xmg-evo-agent-vm > ~/vms/xmg-evo-agent-vm.xml
virsh start xmg-evo-agent-vm
```

That baseline is the artifact the chain starts from. To exercise the chain without touching the
working VM, clone it:

```bash
virt-clone --original xmg-evo-agent-vm --name xmg-evo-agent-vm-rebuild \
  --file /var/lib/libvirt/images/xmg-evo-agent-vm-rebuild.qcow2
```

`virt-clone` resets the MAC address and the machine ID, so the clone gets its own DHCP lease. Give
it a different hostname before putting it on the tailnet. Delete it with
`virsh undefine xmg-evo-agent-vm-rebuild --remove-all-storage` when the test is done.

Everything after the guest install — toolchain, agents, BB, Playwright, agent config — comes from
this repo and should stay scripted. Prefer deterministic scripts over asking an agent to reproduce
machine state by hand.

## 5. Checklist

- [ ] VM runs continuously; disconnecting the client kills nothing
- [ ] named snapshots exist for clean guest and working toolchain
- [ ] disk image and domain XML both included in host backups
- [ ] a restore has been tried: `virsh define` the XML, image back in the pool, VM boots
- [ ] no unpushed work relied upon as storage
- [ ] baseline image kept, and a rebuild from it executed at least once and timed
