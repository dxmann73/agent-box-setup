# 05 – Hypervisor and agent VM

The host runs a KVM/libvirt VM as the agent boundary.

## Host completion preflight

This guide starts only after [04-dev-and-agents.md](04-dev-and-agents.md)'s host completion gate is
satisfied. Confirm the host state with:

```bash
cd ~/projects/agent-box-setup
./verify-setup.sh --host --operational
```

Resolve required host failures before creating or restoring a guest. In particular, all four host
agent CLIs, VS Code settings/shortcuts, the BB desktop AppImage, and the permanent host project
workspace must be ready. The baseline script can prepare KVM/libvirt prerequisites, but it does not
create a domain.

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
virsh net-start default
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
virsh pool-define-as default dir --target /var/lib/libvirt/images
virsh pool-start default
virsh pool-autostart default
mkdir -p ~/vms
```

Skip the `pool-define-as` command when the `default` pool already exists.

## 3. Create the VM

Source the deployment overlay's `box.env` so `VM_NAME`, vCPU, RAM, and disk counts are set. Naming
advice: `<host>-agent-vm` as both libvirt domain and guest hostname. The overlay supplies the live
line; this section keeps flag _reasons_.

The guest uses SeaBIOS, shared `memfd` memory, a libvirt NAT network, a local-only SPICE console,
and virtio video without 3D acceleration. The 2D console permits live snapshots.

Download and verify the current Kubuntu 26.04 ISO, then move it to `/var/lib/libvirt/boot/`:

```bash
cd ~/vms
BASE=https://cdimage.ubuntu.com/kubuntu/releases/26.04/release
curl -fLO -C - "$BASE/kubuntu-26.04.1-desktop-amd64.iso"
curl -fLO "$BASE/SHA256SUMS"
curl -fLO "$BASE/SHA256SUMS.gpg"
gpgv --keyring /usr/share/keyrings/ubuntu-archive-keyring.gpg SHA256SUMS.gpg SHA256SUMS
sha256sum --check --ignore-missing SHA256SUMS
sudo mv kubuntu-26.04.1-desktop-amd64.iso /var/lib/libvirt/boot/
```

```bash
virt-install --name VM_NAME --osinfo detect=on,name=ubuntu24.04 \
  --vcpus VCPUS --cpu host-passthrough \
  --memory MEMORY_MIB --memballoon model=virtio,freePageReporting=on \
  --memorybacking source.type=memfd,access.mode=shared \
  --disk size=DISK_GIB,format=qcow2,bus=virtio,discard=unmap \
  --network network=default,model=virtio \
  --graphics spice,listen=none \
  --video virtio,accel3d=no \
  --cdrom /var/lib/libvirt/boot/kubuntu-26.04.1-desktop-amd64.iso --autostart
```

| Flag                                                         | Reason                                                                                                    |
| ------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------- |
| `--osinfo detect=on,name=ubuntu24.04`                        | Detects the ISO and uses the available Ubuntu profile when the current release is not yet in `osinfo-db`. |
| `--vcpus VCPUS --cpu host-passthrough`                       | Counts come from the overlay. Leave host threads for QEMU, share daemons, and the local model runtime.    |
| `--memory MEMORY_MIB`                                        | Counts come from the overlay. Size for desktop, browser, and concurrent agent sessions.                   |
| `--memorybacking source.type=memfd,access.mode=shared`       | Required by virtiofs shares.                                                                              |
| `--disk size=DISK_GIB,format=qcow2,bus=virtio,discard=unmap` | Sparse qcow2; `discard=unmap` propagates guest TRIM. Size comes from the overlay.                         |
| `--network network=default,model=virtio`                     | Provides Internet NAT and the host model endpoint on one interface.                                       |
| no `--boot`                                                  | Uses QEMU's built-in SeaBIOS, which supports the live-snapshot flow.                                      |
| `--graphics spice,listen=none`                               | Provides a host-only graphical console.                                                                   |
| `--video virtio,accel3d=no`                                  | Keeps the console 2D so QEMU can save live snapshots with memory state.                                   |
| `--autostart`                                                | Starts the VM with the host.                                                                              |

Install Kubuntu with a minimal desktop, one virtual-disk partition, and hostname `VM_NAME`. Then
perform only the console SSH/key/guest-sudo bootstrap in
[`../vm/01-bootstrap.md`](../vm/01-bootstrap.md). From the host, stream the credential-free baseline
into that SSH session:

```bash
cd ~/projects/agent-box-setup
ssh VM_NAME 'bash -s' < machines/vm/guest-baseline.sh
```

## 4. Day-to-day

| Task                | Command                                          |
| ------------------- | ------------------------------------------------ |
| Start / stop        | `virsh start VM_NAME` / `virsh shutdown VM_NAME` |
| Force off           | `virsh destroy VM_NAME`                          |
| Graphical console   | `virt-viewer --attach VM_NAME`                   |
| Edit hardware       | `virsh edit VM_NAME`                             |
| Save the definition | `virsh dumpxml VM_NAME > ~/vms/VM_NAME.xml`      |

## 5. Checklist

- [ ] `kvm-ok` reports KVM acceleration
- [ ] `virsh uri` reports `qemu:///system`
- [ ] default network and storage pool are active
- [ ] `libvirt_guest` and `libvirt` are in the host resolver configuration
- [ ] VM has the overlay CPU, memory, disk, SeaBIOS, `memfd`, and 2D virtio video
- [ ] VM autostarts and `getent hosts VM_NAME` resolves it
- [ ] domain XML is saved to `~/vms/VM_NAME.xml`
