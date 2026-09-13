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

The VM is `xmg-evo-agent-vm`, with 20 vCPUs, 32 GiB RAM, an 80 GiB sparse qcow2 disk, SeaBIOS,
shared `memfd` memory, a libvirt NAT network, a local-only SPICE console, and virtio video without
3D acceleration. The 2D console permits live snapshots.

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
virt-install --name xmg-evo-agent-vm --osinfo detect=on,name=ubuntu24.04 \
  --vcpus 20 --cpu host-passthrough \
  --memory 32768 --memballoon model=virtio,freePageReporting=on \
  --memorybacking source.type=memfd,access.mode=shared \
  --disk size=80,format=qcow2,bus=virtio,discard=unmap \
  --network network=default,model=virtio \
  --graphics spice,listen=none \
  --video virtio,accel3d=no \
  --cdrom /var/lib/libvirt/boot/kubuntu-26.04.1-desktop-amd64.iso --autostart
```

| Flag                                                   | Reason                                                                                                    |
| ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------- |
| `--osinfo detect=on,name=ubuntu24.04`                  | Detects the ISO and uses the available Ubuntu profile when the current release is not yet in `osinfo-db`. |
| `--vcpus 20 --cpu host-passthrough`                    | Reserves four of the host's 24 threads for the host, QEMU, virtiofsd, and the local model runtime.        |
| `--memory 32768`                                       | Supports the desktop, browser, and concurrent agent sessions.                                             |
| `--memorybacking source.type=memfd,access.mode=shared` | Required by virtiofs shares.                                                                              |
| `--disk size=80,format=qcow2,bus=virtio,discard=unmap` | Creates a sparse 80 GiB disk and propagates guest TRIM.                                                   |
| `--network network=default,model=virtio`               | Provides Internet NAT and the host model endpoint on one interface.                                       |
| no `--boot`                                            | Uses QEMU's built-in SeaBIOS, which supports the live-snapshot flow.                                      |
| `--graphics spice,listen=none`                         | Provides a host-only graphical console.                                                                   |
| `--video virtio,accel3d=no`                            | Keeps the console 2D so QEMU can save live snapshots with memory state.                                   |
| `--autostart`                                          | Starts the VM with the host.                                                                              |

Install Kubuntu with a minimal desktop, one virtual-disk partition, and hostname `xmg-evo-agent-vm`.
Then perform only the console SSH/key/guest-sudo bootstrap in
[`../vm/01-bootstrap.md`](../vm/01-bootstrap.md). From the host, stream the credential-free baseline
into that SSH session:

```bash
cd ~/projects/agent-box-setup
ssh xmg-evo-agent-vm 'bash -s' < machines/vm/guest-baseline.sh
```

## 4. Day-to-day

| Task                | Command                                                            |
| ------------------- | ------------------------------------------------------------------ |
| Start / stop        | `virsh start xmg-evo-agent-vm` / `virsh shutdown xmg-evo-agent-vm` |
| Force off           | `virsh destroy xmg-evo-agent-vm`                                   |
| Graphical console   | `virt-viewer --attach xmg-evo-agent-vm`                            |
| Edit hardware       | `virsh edit xmg-evo-agent-vm`                                      |
| Save the definition | `virsh dumpxml xmg-evo-agent-vm > ~/vms/xmg-evo-agent-vm.xml`      |

## 5. Checklist

- [ ] `kvm-ok` reports KVM acceleration
- [ ] `virsh uri` reports `qemu:///system`
- [ ] default network and storage pool are active
- [ ] `libvirt_guest` and `libvirt` are in the host resolver configuration
- [ ] VM has the configured CPU, memory, disk, SeaBIOS, `memfd`, and 2D virtio video
- [ ] VM autostarts and `getent hosts xmg-evo-agent-vm` resolves it
- [ ] domain XML is saved to `~/vms/xmg-evo-agent-vm.xml`
