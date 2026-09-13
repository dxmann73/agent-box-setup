# 07 – Snapshots, persistence and recovery

The VM stays running while clients disconnect. BB sessions and agent processes continue in the VM.

## 1. Live snapshots

Use live qcow2 snapshots. The VM uses SeaBIOS and virtio video without 3D acceleration so QEMU can
save memory state during a snapshot.

```bash
virsh snapshot-create-as xmg-evo-agent-vm clean-guest \
  --description 'base applications, no credentials' --atomic
virsh snapshot-create-as xmg-evo-agent-vm credentialed \
  --description 'credentialed live state' --atomic
virsh snapshot-list xmg-evo-agent-vm --tree
virsh snapshot-current xmg-evo-agent-vm --name
```

Take these snapshots:

| Snapshot         | When                                                                              |
| ---------------- | --------------------------------------------------------------------------------- |
| `clean-guest`    | after [01-bootstrap.md](01-bootstrap.md) passes `--bootstrap`, before credentials |
| `credentialed`   | after credentials, once a live disk backup is proven                              |
| `pre-experiment` | before an invasive experiment                                                     |

`clean-guest` is a bootstrap gate, not a required long-lived restore point. After a proven
credentialed disk backup and a `credentialed` live snapshot exist, delete it. Snapshot revert
restores that snapshot's domain XML: virtiofs devices added later disappear until you revert a
snapshot that includes them.

Delete children first. Never `virsh snapshot-delete --children` or `--metadata` to force removal.

```bash
virsh snapshot-delete xmg-evo-agent-vm pre-experiment
virsh snapshot-delete xmg-evo-agent-vm clean-guest
```

## 2. Live backup

Create a full live disk backup without shutting down the VM. The host-side
[`backup-agent-vm.sh`](../host/backup-agent-vm.sh) uses libvirt's push backup API, which keeps the
guest running while QEMU copies a consistent disk image. A live backup is disk-only: a restore
cold-boots, and RAM is not in the image.

```bash
cd ~/projects/agent-box-setup
machines/host/backup-agent-vm.sh --dry-run --label current-credentialed
machines/host/backup-agent-vm.sh --label current-credentialed
```

`--domain` names the running libvirt guest (default `xmg-evo-agent-vm`). `--label` is required and
becomes the human suffix (`current-credentialed`). Each run creates a non-overwriting set at
`~/backup/vm/<guest>/<UTC-timestamp>-<label>/`, with a UTC stamp of `YYYY-MM-DDTHHMMSSZ` so lexical
order is chronological. Example:
`~/backup/vm/xmg-evo-agent-vm/2026-09-13T115618Z-current-credentialed/`.

The set contains:

- `disk-vda.qcow2`, the full live disk backup;
- `domain.xml`, the domain definition at backup start;
- `backup.xml`, the libvirt backup request; and
- `SHA256SUMS`, checksums written after `qemu-img check` succeeds.

The script makes `~/backup/vm` accessible to `libvirt-qemu`, because that QEMU user writes the
live-backup target. It requires `sudo` for that access setup and for the disk-image validation. Set
`SUDO_ASKPASS` to a GUI askpass (for example `/usr/bin/ksshaskpass`) when the script has no TTY.
Before starting the job, it requires free space for the complete virtual disk plus a 1 GiB reserve.
The first measured credentialed set was about 14 GiB; `qemu-img measure` matched that file, not the
virtual size. Do not shrink from `du` output. The guest `vda` is 80 GiB
([`../host/05-hypervisor.md`](../host/05-hypervisor.md)). A separate `clean-guest` disk backup is
optional and is not required once the credentialed set is proven.

This is deliberately a same-host recovery copy. It protects against a failed guest update or an
accidental change to the VM disk, but not host-disk loss, theft, fire, or ransomware. Keep project
work pushed to its remote. Geld virtiofs mounts are host data: they are not in the backup.

### 2.1 Prove a backup on a disposable overlay

Do not `virsh define` the saved `domain.xml` onto the primary. Boot a **new** domain from a writable
overlay whose backing file is the backup. Keep the primary running. Do not attach the Geld virtiofs
shares to the test domain (two writers to the same share).

```bash
BACKUP="$HOME/backup/vm/xmg-evo-agent-vm/REPLACE-WITH-PRINTED-SET"
OVERLAY="$BACKUP/overlay-test.qcow2"
TEST_XML="$BACKUP/restore-test.xml"
TEST_NAME="xmg-evo-agent-vm-restore-test"

qemu-img create -f qcow2 -F qcow2 -b "$BACKUP/disk-vda.qcow2" "$OVERLAY"
chmod 0660 "$OVERLAY"
setfacl -m u:libvirt-qemu:rw- "$OVERLAY"

python3 - "$BACKUP/domain.xml" "$OVERLAY" "$TEST_XML" "$TEST_NAME" <<'PY'
import sys, uuid, xml.etree.ElementTree as ET

src, overlay, dest, name = sys.argv[1:]
tree = ET.parse(src)
root = tree.getroot()
root.find("name").text = name
root.find("uuid").text = str(uuid.uuid4())
for tag in ("memory", "currentMemory"):
    node = root.find(tag)
    if node is not None:
        node.set("unit", "KiB")
        node.text = "8388608"
devices = root.find("devices")
for fs in list(devices.findall("filesystem")):
    devices.remove(fs)
disk = devices.find("disk[@device='disk']")
source = disk.find("source")
source.set("file", overlay)
source.attrib.pop("index", None)
backing = disk.find("backingStore")
if backing is not None:
    disk.remove(backing)
mac = devices.find("interface/mac")
mac.set("address", "52:54:00:%02x:%02x:%02x" % tuple(uuid.uuid4().bytes[:3]))
interface = devices.find("interface")
link = interface.find("link")
if link is None:
    link = ET.SubElement(interface, "link")
link.set("state", "down")
iface_source = devices.find("interface/source")
for key in ("portid", "bridge"):
    iface_source.attrib.pop(key, None)
tree.write(dest)
PY

virsh define "$TEST_XML"
virsh start "$TEST_NAME"
```

The cloned network link starts down so its copied Tailscale identity cannot contact the coordination
server. Wait for the QEMU guest agent, then use its network-independent command channel to stop and
mask `tailscaled` before raising the link. `guest-exec` is asynchronous: record the returned PID and
confirm `guest-exec-status` reports `"exited": true` and `"exitcode": 0` for each command.

```bash
virsh qemu-agent-command "$TEST_NAME" '{"execute":"guest-ping"}'
virsh qemu-agent-command "$TEST_NAME" \
  '{"execute":"guest-exec","arguments":{"path":"/usr/bin/systemctl","arg":["stop","tailscaled"],"capture-output":true}}'
virsh qemu-agent-command "$TEST_NAME" \
  '{"execute":"guest-exec-status","arguments":{"pid":REPLACE_WITH_RETURNED_PID}}'
virsh qemu-agent-command "$TEST_NAME" \
  '{"execute":"guest-exec","arguments":{"path":"/usr/bin/systemctl","arg":["mask","tailscaled"],"capture-output":true}}'
virsh qemu-agent-command "$TEST_NAME" \
  '{"execute":"guest-exec-status","arguments":{"pid":REPLACE_WITH_RETURNED_PID}}'
virsh domif-setlink "$TEST_NAME" REPLACE_WITH_INTERFACE_TARGET up
```

Get the interface target from `virsh domiflist "$TEST_NAME"`. Wait for a DHCP lease on `default`
that matches the new MAC, then SSH **that IP** with a new host key. The hardened host-automation key
still works because this connection originates from the hypervisor bridge. Do not
`ssh xmg-evo-agent-vm`: libvirt NSS publishes the clone's DHCP hostname and will steal the name from
the primary.

Confirm the identity is still masked and give the clone a distinct hostname:

```bash
systemctl is-enabled tailscaled        # masked
systemctl is-active tailscaled         # inactive
sudo hostnamectl set-hostname restore-test
```

Do **not** join Tailscale. The clone has the primary's node identity and would fight it. Stop
`tailscaled` as soon as SSH is up.

The clone hostname is `restore-test`, so `./verify-setup.sh --vm --bootstrap` fails the hostname
check on purpose. Treat the other bootstrap checks as the restore proof. Do not run `--full` on the
clone.

```bash
virsh destroy "$TEST_NAME"
virsh undefine "$TEST_NAME"
rm -f "$OVERLAY" "$TEST_XML"
```

Keep `disk-vda.qcow2`, `domain.xml`, `backup.xml`, and `SHA256SUMS`. QEMU may change ownership of
the backing file while the overlay runs; confirm `SHA256SUMS` still matches.

## 3. Acceptance rebuild test

After reviewing a change to `guest-baseline.sh`, run the host-driven baseline as the acceptance test
on a credential-free guest. Do not fold provider, GitHub, Firecrawl, Tailscale, model, or share
credentials into that test.

If `clean-guest` is still present:

```bash
virsh snapshot-revert xmg-evo-agent-vm clean-guest
cd ~/projects/agent-box-setup
ssh xmg-evo-agent-vm 'bash -s' < machines/vm/guest-baseline.sh
ssh -t xmg-evo-agent-vm \
  'cd ~/projects/agent-box-setup && ./verify-setup.sh --vm --bootstrap'
```

If you already deleted `clean-guest`, use a disposable overlay of a retained clean disk backup
(section 2.1) or a new guest (section 4). Park the credentialed VM first; do not run the baseline
against the live credentialed domain.

## 4. Rebuild test

A rebuild is a **new** guest, not a clone of the live disk. Recover the current VM with overlay
restore (section 2.1). Do not `virt-clone` the primary: that copies credentials and the Tailscale
node key, needs a shutdown, and is not a clean baseline.

To prove the setup can be recreated, leave the credentialed VM running and follow
[`../host/05-hypervisor.md`](../host/05-hypervisor.md) plus [`01-bootstrap.md`](01-bootstrap.md) for
a second domain with a distinct name, hostname, and MAC. Stream `guest-baseline.sh`, then
`./verify-setup.sh --vm --bootstrap`. Take `clean-guest` on that new guest before any credentials.

Remove the rebuild guest when finished:

```bash
virsh undefine xmg-evo-agent-vm-rebuild --remove-all-storage
```

## 5. Checklist

- [ ] `clean-guest` was taken after `--bootstrap` and before credentials
- [ ] a `credentialed` live snapshot exists after a proven disk backup
- [ ] disk image and domain XML are in `~/backup/vm/<guest>/` and overlay-restore was proven
- [ ] restore and rebuild tests have completed
- [ ] project work is pushed
