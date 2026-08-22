# 06 – Shared folders

Projects live inside the VM (specification §8). Occasionally an agent has to work on files that
belong to the host — the Dropbox tax-advisor folder, for example. Those are shared in **one named
directory at a time**, over virtiofs.

Sharing punches a hole in the boundary. Everything shared is readable by every agent in the VM, and
for a writable Dropbox path every write syncs straight back to the cloud. Share the narrowest
directory that makes the task possible, read-only unless writing is the point, and detach it
afterwards.

Never share: `$HOME`, the Dropbox root, `~/.ssh`, browser profiles, `~/Documents` wholesale.

Prerequisite: the domain was created with shared memory backing
(`<memoryBacking><source type='memfd'/><access mode='shared'/>`), see
[`../host/05-hypervisor.md`](../host/05-hypervisor.md). Without it virtiofs devices cannot attach.
Every `virsh` below assumes `LIBVIRT_DEFAULT_URI=qemu:///system` is exported (same file, §3).

## 1. Host side

One XML file per share. `~/vms/share-tax.xml`:

```xml
<filesystem type='mount' accessmode='passthrough'>
  <driver type='virtiofs'/>
  <source dir='/home/CHANGE-ME/Dropbox/Tax'/>
  <target dir='tax'/>
  <readonly/>
</filesystem>
```

`<target dir='tax'>` is a mount **tag**, not a path — the guest mounts it by that name. Attach it to
the running VM and to its persistent definition:

```bash
virsh attach-device agent-vm ~/vms/share-tax.xml --live --config
virsh dumpxml agent-vm | grep -A6 filesystem
```

Drop `<readonly/>` only when the agent genuinely has to write. Enforcing it here rather than in the
guest is the point: a guest-side `-o ro` mount can be remounted read-write by anything with root in
the VM, and agents have root in the VM.

`<readonly/>` for virtiofs needs libvirt ≥ 11.0 and virtiofsd ≥ 1.13 — Kubuntu 26.04 ships 12.0 and
1.13. If the domain refuses to start after attaching a share, read
`/var/log/libvirt/qemu/agent-vm.log`; an AppArmor denial on the source path shows up there.

## 2. Guest side

```bash
sudo mkdir -p /mnt/shares/tax
sudo mount -t virtiofs tax /mnt/shares/tax
ls /mnt/shares/tax
```

Persist it in `/etc/fstab`, one line per share:

```text
tax   /mnt/shares/tax   virtiofs   ro,nofail   0 0
```

`nofail` matters: without it the guest drops to emergency mode when a share has been detached on the
host. Link the shares actually in use into the home directory:

```bash
mkdir -p ~/shares && ln -s /mnt/shares/tax ~/shares/tax
```

No `qemu-guest-agent` involvement and no FUSE helper — virtiofs is a kernel filesystem in the guest.

## 3. Unshare when done

```bash
# guest
sudo umount /mnt/shares/tax
# host
virsh detach-device agent-vm ~/vms/share-tax.xml --live --config
```

The boundary is only as good as the current share list. Review it with
`virsh dumpxml agent-vm | grep -c '<filesystem'` and remove what no task needs.

## 4. Working rules

- point agents at the specific share path, not at `/mnt/shares`
- a share is not a backup target and not a place for build output — keep generated files in
  `~/projects`
- no credentials in a share, see [05-credentials.md](05-credentials.md)
- shares are host state: snapshots of the VM do not contain them, and reverting the VM does not
  revert a file an agent changed in a share ([07-snapshots.md](07-snapshots.md))

## 5. Checklist

- [ ] shares are individually named directories, never `$HOME` or a sync root
- [ ] `<readonly/>` present wherever writing is not needed
- [ ] mount tag mounts in the guest and survives a reboot via `fstab` with `nofail`
- [ ] current share list reviewed, stale devices detached from `--live --config`

Next: [07-snapshots.md](07-snapshots.md)
