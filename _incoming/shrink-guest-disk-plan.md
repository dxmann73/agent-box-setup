# Shrink the agent VM disk from 200 GiB to 80 GiB

**Status:** to do. Offline maintenance. Keep the proven credentialed live backup until a
new 80 GiB backup is overlay-proven.

Do not include virtiofs-hosted Dropbox data. Geld stays on the host.

## Why shrink `vda`

Three different sizes are in play:

| Size | Current | What it is |
| ---- | ------- | ---------- |
| Guest filesystem used | ~13 GiB on `/` | Actual files |
| qcow2 allocated | ~23 GiB | Host clusters in use |
| Virtual disk (`vda`) | 200 GiB | What QEMU and the partition table advertise |

The live backup file was ~18 GiB because qcow2 only copies allocated clusters. The backup
script's space guard still uses **virtual** size + 1 GiB (~201 GiB). Compacting the qcow2
file without shrinking `vda` does not lower that guard, and the guest can still grow toward
200 GiB.

So yes: shrink `vda` (virtual size + partition + filesystem), not only the host file.

80 GiB is enough: ~13 GiB used, headroom for projects, Docker, Playwright, and growth.
Future `virt-install` in [`machines/host/05-hypervisor.md`](../machines/host/05-hypervisor.md)
should use `--disk size=80,...`.

## Is it easy?

Tractable, not live. This guest is the easy layout: SeaBIOS, DOS/MBR, one `vda1` ext4 root,
no LVM, no EFI, no separate `/boot`. It still needs a shutdown, and the internal
`credentialed` snapshot must be removed (or recreated after) because internal snapshots
block a clean resize.

Keep [`~/backup/vm/xmg-evo-agent-vm/2026-09-13T104643Z-current-credentialed/`](~/backup/vm/xmg-evo-agent-vm/2026-09-13T104643Z-current-credentialed/)
until the post-shrink backup is proven. Overlay-restore that set if the shrink fails.

## Recommended method

Use host-side `virt-resize` on a **copy**. Do not resize the live image in place.

1. Confirm used space (`df -h /`) stays well under 80 GiB. Leave several GiB free inside
   the new filesystem.
2. `virsh snapshot-delete xmg-evo-agent-vm credentialed` after a fresh live snapshot is
   optional; deleting it is required before replacing the disk. Recreate `credentialed`
   after boot.
3. Shut down the guest. Do not `destroy`.
4. Copy the qcow2, then resize the copy:

   ```bash
   IMG=/var/lib/libvirt/images/xmg-evo-agent-vm.qcow2
   NEW=/var/lib/libvirt/images/xmg-evo-agent-vm-80g.qcow2
   sudo qemu-img create -f qcow2 "$NEW" 80G
   sudo virt-resize --shrink /dev/sda1 "$IMG" "$NEW"
   sudo qemu-img check "$NEW"
   ```

   libvirt presents `vda`; libguestfs often names the same disk `sda`. Confirm with
   `virt-filesystems -a "$IMG" --partitions` before shrinking.

5. Point the domain at `$NEW` (or swap filenames), boot, check `lsblk` and `df`.
6. Recreate the `credentialed` live snapshot.
7. Live-backup `--label current-credentialed` and overlay-prove it. Then the space guard
   can drop to the new virtual size + 1 GiB (81 GiB) or to `qemu-img measure` plus reserve.
8. Update `05-hypervisor.md` (`size=80`) and the measured-size note in
   [`machines/vm/07-snapshots.md`](../machines/vm/07-snapshots.md).
9. Remove the 200 GiB qcow2 only after the new backup is proven.

`qemu-img resize --shrink` alone is not enough: the partition and ext4 must shrink first.
`virt-resize --shrink` does that in one offline pass. Shrinking a mounted root with
`resize2fs` is the harder path; skip it.

## Out of scope

- Host backups.
- Shrinking from `du` of the existing 18 GiB backup file.
- Changing RAM or vCPU.

## The shutdown / `virt-clone` rebuild (`07-snapshots.md` §4)

That section is a **cold clone test**, not a shrink, and not the restore path anymore.

It shuts the guest down, copies the qcow2 to `baseline-clean-guest.qcow2`, then
`virt-clone`s a disposable domain. That was the rebuild proof before live backup existed.
Overlay restore of `~/backup/vm/.../disk-vda.qcow2` replaced `virsh define domain.xml` as
the restore recipe.

Problems with keeping §4 as written:

- It requires shutdown. Live backup does not.
- After deleting `clean-guest`, a copy of the current disk is credentialed, not a clean
  baseline. The filename `baseline-clean-guest.qcow2` would be a lie.
- A clone of the credentialed disk has the same Tailscale node key as overlay restore.
  Same rule: unique hostname, do not join the tailnet, SSH by lease IP.
- A real "recreate the VM" test is new `virt-install` + `guest-baseline.sh`, not cloning
  the live disk.

Recommendation: drop §4 from the standing procedure, or rewrite it as an optional "new
guest from ISO" rebuild. Do not treat `virt-clone` of the running disk as a clean-guest
factory. Do this rewrite in the same session as the shrink, or immediately after, so the
guide does not keep two restore stories.
