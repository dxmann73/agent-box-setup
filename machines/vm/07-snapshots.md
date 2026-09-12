# 07 – Snapshots, persistence and recovery

The VM stays running while clients disconnect. BB sessions and agent processes continue in the VM.

## 1. Live snapshots

Use live qcow2 snapshots. The VM uses SeaBIOS and virtio video without 3D acceleration so QEMU can
save memory state during a snapshot.

```bash
virsh snapshot-create-as xmg-evo-agent-vm clean-guest \
  --description 'base applications, no credentials' --atomic
virsh snapshot-list xmg-evo-agent-vm --tree
virsh snapshot-revert xmg-evo-agent-vm clean-guest
virsh snapshot-delete xmg-evo-agent-vm pre-experiment
```

Take these snapshots:

| Snapshot         | When                                                                   |
| ---------------- | ---------------------------------------------------------------------- |
| `clean-guest`    | after [01-bootstrap.md](01-bootstrap.md) §6, before credentials        |
| `toolchain`      | after [02-dev-and-agents.md](02-dev-and-agents.md) passes verification |
| `pre-experiment` | before an invasive experiment                                          |

Delete a `pre-experiment` snapshot once it is no longer needed.

## 2. Backup

Back up the powered-off VM's disk and domain XML:

```bash
virsh shutdown xmg-evo-agent-vm
virsh dumpxml xmg-evo-agent-vm > ~/vms/xmg-evo-agent-vm.xml
sudo cp --sparse=always /var/lib/libvirt/images/xmg-evo-agent-vm.qcow2 /backup/target/
virsh start xmg-evo-agent-vm
```

Restore the domain with:

```bash
virsh define ~/vms/xmg-evo-agent-vm.xml
```

Keep project work pushed to its remote.

## 3. Rebuild test

Create a clean baseline after the VM is verified:

```bash
virsh shutdown xmg-evo-agent-vm
sudo cp --sparse=always /var/lib/libvirt/images/xmg-evo-agent-vm.qcow2 \
  /var/lib/libvirt/images/baseline-clean-guest.qcow2
virsh dumpxml xmg-evo-agent-vm > ~/vms/xmg-evo-agent-vm.xml
virsh start xmg-evo-agent-vm
```

Test the setup on a clone:

```bash
virt-clone --original xmg-evo-agent-vm --name xmg-evo-agent-vm-rebuild \
  --file /var/lib/libvirt/images/xmg-evo-agent-vm-rebuild.qcow2
```

Give the clone a unique hostname before connecting it to the tailnet. Remove it after the test:

```bash
virsh undefine xmg-evo-agent-vm-rebuild --remove-all-storage
```

## 4. Checklist

- [ ] `clean-guest` and `toolchain` snapshots exist
- [ ] disk image and domain XML are in host backups
- [ ] restore and rebuild tests have completed
- [ ] project work is pushed
