# 06 – Shared folders

Projects live inside the VM (specification §8). Occasionally an agent has to work on files that
belong to the host — the Dropbox tax-advisor folder, for example. Those are shared in **one named
directory at a time**.

Sharing punches a hole in the boundary. Everything shared is readable and writable by every agent in
the VM, and for a Dropbox path every write syncs straight back to the cloud. Share the narrowest
directory that makes the task possible, and unshare it afterwards.

Never share: `$HOME`, the Dropbox root, `~/.ssh`, browser profiles, `~/Documents` wholesale.

## 1. Host side

VMware Workstation Pro > VM > Settings > Options > Shared Folders:

- set to **Always enabled**
- add one folder per share, named after its purpose, e.g. `tax` → `/home/you/Dropbox/Tax`
- mark the share read-only unless the agent genuinely has to write

Verify `open-vm-tools` is installed on the host, see
[`../host/05-hypervisor.md`](../host/05-hypervisor.md).

## 2. Guest side

`open-vm-tools` must be present in the guest ([01-bootstrap.md](01-bootstrap.md)). Mount the share
tree via fstab:

```bash
sudo nano /etc/fstab

# add
#.host:/   /mnt/hgfs   fuse.vmhgfs-fuse   allow_other,uid=1000,gid=1000   0   0
```

Test it safely:

```bash
sudo mount -a
ls /mnt/hgfs
```

Link the shares you actually use into the home directory:

```bash
ln -s /mnt/hgfs/tax ~/shares/tax
```

## 3. Working rules

- point agents at the specific share path, not at `/mnt/hgfs`
- a share is not a backup target and not a place for build output — keep generated files in
  `~/projects`
- no credentials in a share, see [05-credentials.md](05-credentials.md)
- remove the share in VM settings when the task is done; the boundary is only as good as the
  smallest current share list

## 4. Checklist

- [ ] shares are individually named directories, never `$HOME` or a sync root
- [ ] read-only wherever writing is not needed
- [ ] `/mnt/hgfs` mounts and survives reboot
- [ ] current share list reviewed and stale entries removed

Next: [07-snapshots.md](07-snapshots.md)
