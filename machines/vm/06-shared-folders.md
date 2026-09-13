# 06 – Shared folders

Projects live inside the VM (specification §8). Occasionally an agent has to work on a narrow host
directory. Those are shared as individually named directories over virtiofs.

Sharing punches a hole in the boundary. Everything shared is readable by every agent in the VM, and
for a writable sync path every write propagates to the host. Share the narrowest directory that
makes the task possible, read-only unless writing is the point, and detach it afterwards.

Never share: `$HOME`, a sync root, `~/.ssh`, browser profiles, `~/Documents` wholesale.

Concrete source paths, mount tags, writable exceptions, and VM names belong in deployment-specific
setup documentation. The DaveBox recipe is
[maintained separately](https://github.com/dxmann73/dave.box-setup/blob/main/setup/11-agent-vm-shared-folders.md).

Prerequisite: the domain was created with shared memory backing
(`<memoryBacking><source type='memfd'/><access mode='shared'/>`), see
[`../host/05-hypervisor.md`](../host/05-hypervisor.md). Without it virtiofs devices cannot attach.
Every `virsh` below assumes `LIBVIRT_DEFAULT_URI=qemu:///system` is exported (same file, §3).
Replace `VM_NAME` below with the deployment's libvirt domain name.

## 1. Host side

Create one XML file per share. For a read-only share, `~/vms/share-example.xml` is:

```xml
<filesystem type='mount' accessmode='passthrough'>
  <driver type='virtiofs'/>
  <source dir='/path/to/narrow/host-directory'/>
  <target dir='example'/>
  <readonly/>
</filesystem>
```

`<target dir='example'>` is a mount **tag**, not a path — the guest mounts it by that name. Attach
it to the running VM and to its persistent definition:

```bash
virsh attach-device VM_NAME ~/vms/share-example.xml --live --config
virsh dumpxml VM_NAME | grep -A6 filesystem
```

Drop `<readonly/>` only when the agent genuinely has to write. Enforcing it here rather than in the
guest is the point: a guest-side `-o ro` mount can be remounted read-write by anything with root in
the VM, and agents have root in the VM.

`<readonly/>` for virtiofs needs libvirt ≥ 11.0 and virtiofsd ≥ 1.13 — Kubuntu 26.04 ships 12.0 and
1.13. If the domain refuses to start after attaching a share, read
`/var/log/libvirt/qemu/VM_NAME.log`; an AppArmor denial on the source path shows up there.

## 2. Guest side

```bash
sudo mkdir -p /mnt/shares/example
sudo mount -t virtiofs example /mnt/shares/example
ls /mnt/shares/example
```

Persist it in `/etc/fstab`, one line per share:

```text
example   /mnt/shares/example   virtiofs   ro,nofail   0 0
```

`nofail` matters: without it the guest drops to emergency mode when a share has been detached on the
host. Link the shares actually in use into the home directory:

```bash
mkdir -p ~/shares && ln -s /mnt/shares/example ~/shares/example
```

No `qemu-guest-agent` involvement and no FUSE helper — virtiofs is a kernel filesystem in the guest.

### Read-only parent with writable child

To make one child directory writable within a read-only parent, attach two devices: the parent with
`<readonly/>` and the child without it. Mount the parent first, then mount the child over its
corresponding path inside the parent mount. The host enforces the boundary, so all other paths in
the parent remain read-only. Put actual paths and tags in the deployment-specific recipe.

## 3. Unshare when done

Unmount a guest share before detaching its matching host device:

```bash
sudo umount /mnt/shares/example
virsh detach-device VM_NAME ~/vms/share-example.xml --live --config
```

For nested mounts, unmount and detach the child before the parent.

The boundary is only as good as the current share list. Review it with
`virsh dumpxml VM_NAME | grep -c '<filesystem'` and remove what no task needs.

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
- [ ] nested writable shares are mounted below their read-only parents and tested explicitly
- [ ] current share list reviewed, stale devices detached from `--live --config`

Next: [07-snapshots.md](07-snapshots.md)
