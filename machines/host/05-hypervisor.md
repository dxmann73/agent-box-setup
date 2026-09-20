# 05 – Hypervisor and agent VM

The host runs a KVM/libvirt VM as the agent boundary.

## Two phases

Sections 1–3 prepare virtualization and installation media after the host baseline. They require no
coding-agent authentication, editor, project inventory or existing guest. Check installed state
first; `prepare-host-system.sh` may already have completed infrastructure setup.

A deployment may now create a separate personal browser guest before the remaining host logins. Use
that overlay's guest configuration and acceptance checks; do not run the agent-VM baseline in it. Do
not copy this file's 2D `accel3d=no` video flags into that guest; its overlay enables SPICE GL when
browser and video playback need it. Section 4 is the later **agent-VM** branch, after host tooling
completion.

## 1. Install KVM/libvirt

```bash
sudo apt install -y cpu-checker qemu-system-x86 libvirt-daemon-system libvirt-clients virtinst \
  virt-manager virt-viewer virtiofsd libnss-libvirt
kvm-ok
sudo usermod -aG libvirt,kvm "$USER"
```

Log out and back in. Set the system libvirt URI in the shell configuration:

```bash
export LIBVIRT_DEFAULT_URI=qemu:///system
virsh uri
virsh net-list --name | grep -Fxq default || virsh net-start default
virsh net-autostart default
```

Add `libvirt_guest` and `libvirt` after `files` on the `hosts:` line in `/etc/nsswitch.conf`:

```bash
sudo python3 - <<'PYCODE'
from pathlib import Path

path = Path('/etc/nsswitch.conf')
lines = path.read_text().splitlines()
for index, line in enumerate(lines):
    if line.startswith('hosts:'):
        fields = line.split()
        for module in ('libvirt_guest', 'libvirt'):
            if module not in fields:
                fields.insert(2, module)
        lines[index] = ' '.join(fields)
path.write_text('\n'.join(lines) + '\n')
PYCODE
```

## 2. Storage

Use the `default` pool for VM disks and `~/vms/` for ISO files and domain XML:

```bash
virsh pool-list --all
virsh pool-info default >/dev/null 2>&1 || \
  virsh pool-define-as default dir --target /var/lib/libvirt/images
virsh pool-list --name | grep -Fxq default || virsh pool-start default
virsh pool-autostart default
mkdir -p ~/vms
```

Skip the `pool-define-as` command when the `default` pool already exists.

## 3. Installation media

Reuse an existing verified ISO. For a fresh installation, download and verify the Kubuntu ISO, then
move it to `/var/lib/libvirt/boot/`:

```bash
cd ~/vms
BASE=https://cdimage.ubuntu.com/kubuntu/releases/26.04/release
curl -fLO -C - "$BASE/kubuntu-26.04.1-desktop-amd64.iso"
curl -fLO "$BASE/SHA256SUMS"
curl -fLO "$BASE/SHA256SUMS.gpg"
gpgv --keyring /usr/share/keyrings/ubuntu-archive-keyring.gpg SHA256SUMS.gpg SHA256SUMS
sha256sum --check --ignore-missing SHA256SUMS
sudo install -d -m 0755 /var/lib/libvirt/boot
sudo mv kubuntu-26.04.1-desktop-amd64.iso /var/lib/libvirt/boot/
```

Run the read-only infrastructure check, then confirm the chosen guest's CPU/RAM/disk requirements
and network policy:

```bash
~/projects/agent-box-setup/machines/host/verify-virtualization.sh
```

For a personal browser guest, return to the deployment overlay here. Do not continue into the
agent-VM branch or reuse its resource variables unchanged.

## 4. Create the agent VM

Complete [04-dev-and-agents.md](04-dev-and-agents.md), including its operational verification,
before this branch. A personal browser guest uses the earlier infrastructure checkpoint instead.

```bash
cd ~/projects/agent-box-setup
./verify-setup.sh --host --operational
```

Source the deployment overlay's `box.env` so `AGENT_BOX_VM_HOSTNAME`, `AGENT_BOX_VM_VCPUS`,
`AGENT_BOX_VM_MEMORY_MIB`, and `AGENT_BOX_VM_DISK_GIB` are set. Naming advice: `<host>-agent-vm` as
both libvirt domain and guest hostname. The overlay supplies the live values; this section keeps
flag notes.

This agent VM uses SeaBIOS, shared `memfd` memory, a libvirt NAT network, a local-only SPICE
console, and virtio video without 3D acceleration. The 2D console permits live snapshots. A personal
browser guest is a different domain and does not use these video flags.

```bash
virt-install --name "$AGENT_BOX_VM_HOSTNAME" --osinfo detect=on,name=ubuntu24.04 \
  --vcpus "$AGENT_BOX_VM_VCPUS" --cpu host-passthrough \
  --memory "$AGENT_BOX_VM_MEMORY_MIB" --memballoon model=virtio,freePageReporting=on \
  --memorybacking source.type=memfd,access.mode=shared \
  --disk size="$AGENT_BOX_VM_DISK_GIB",format=qcow2,bus=virtio,discard=unmap \
  --network network=default,model=virtio \
  --graphics spice,listen=none \
  --video virtio,accel3d=no \
  --cdrom /var/lib/libvirt/boot/kubuntu-26.04.1-desktop-amd64.iso --autostart
```

| Flag                                                    | Reason                                                                                                    |
| ------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `--osinfo detect=on,name=ubuntu24.04`                   | Detects the ISO and uses the available Ubuntu profile when the current release is not yet in `osinfo-db`. |
| `--vcpus ... --cpu host-passthrough`                    | Counts come from the overlay. Leave host threads for QEMU, share daemons, and the local model runtime.    |
| `--memory ...`                                          | Counts come from the overlay. Size for desktop, browser, and concurrent agent sessions.                   |
| `--memorybacking source.type=memfd,access.mode=shared`  | Required by virtiofs shares.                                                                              |
| `--disk size=...,format=qcow2,bus=virtio,discard=unmap` | Sparse qcow2; `discard=unmap` propagates guest TRIM. Size comes from the overlay.                         |
| `--network network=default,model=virtio`                | Provides Internet NAT and the host model endpoint on one interface.                                       |
| no `--boot`                                             | Uses QEMU's built-in SeaBIOS, which supports the live-snapshot flow.                                      |
| `--graphics spice,listen=none`                          | Provides a host-only graphical console.                                                                   |
| `--video virtio,accel3d=no`                             | Keeps the console 2D so QEMU can save live snapshots with memory state.                                   |
| `--autostart`                                           | Starts the VM with the host.                                                                              |

Install Kubuntu with a minimal desktop, one virtual-disk partition, and hostname
`$AGENT_BOX_VM_HOSTNAME`. Then perform only the console SSH/key/guest-sudo bootstrap in
[`../vm/01-bootstrap.md`](../vm/01-bootstrap.md). From the host, stream the credential-free baseline
into that SSH session:

```bash
cd ~/projects/agent-box-setup
ssh "$AGENT_BOX_VM_HOSTNAME" \
  "AGENT_BOX_VM_HOSTNAME='$AGENT_BOX_VM_HOSTNAME' bash -s" \
  < machines/vm/guest-baseline.sh
```

## 5. Day-to-day

| Task                | Command                                             |
| ------------------- | --------------------------------------------------- |
| Start / stop        | `virsh start VM_NAME` / `virsh shutdown VM_NAME`    |
| Hibernate / restore | `virsh managedsave VM_NAME` / `virsh start VM_NAME` |
| Force off           | `virsh destroy VM_NAME`                             |
| Graphical console   | `virt-viewer --attach VM_NAME`                      |
| Edit hardware       | `virsh edit VM_NAME`                                |
| Save the definition | `virsh dumpxml VM_NAME > ~/vms/VM_NAME.xml`         |

Host poweroff must not ACPI-stop the agent VM. Set `ON_SHUTDOWN=suspend` in
`/etc/default/libvirt-guests` so `libvirt-guests.service` runs `virsh managedsave` on every running
domain. Leave `ON_BOOT=ignore`. The agent VM's libvirt autostart restores that save, so in-guest
processes resume. A 3D SPICE-GL guest cannot save (`virgl is not yet migratable`); leave its
autostart off and accept a cold start.

## 6. Checklist

- [ ] `kvm-ok` reports KVM acceleration
- [ ] `virsh uri` reports `qemu:///system`
- [ ] default network and storage pool are active
- [ ] `libvirt_guest` and `libvirt` are in the host resolver configuration
- [ ] VM has the overlay CPU, memory, disk, SeaBIOS, `memfd`, and 2D virtio video
- [ ] VM autostarts and `getent hosts VM_NAME` resolves it
- [ ] `/etc/default/libvirt-guests` has `ON_SHUTDOWN=suspend`
- [ ] domain XML is saved to `~/vms/VM_NAME.xml`
