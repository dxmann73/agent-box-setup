# 05 – Hypervisor and agent VM

The host runs the hypervisor; the VM it creates is the security boundary for all agent work
(specification §3).

> **Status: unverified.** The commands have not been run on this box yet. Correct them from
> the real setup and delete this notice.

Every `virsh` command in this file and in [`../vm/`](../vm/) assumes
`LIBVIRT_DEFAULT_URI=qemu:///system` is exported (§3).

## 1. Why KVM/libvirt

KVM is the hypervisor in the Linux kernel. libvirt manages it, `virt-install` creates guests from
the command line, `virt-manager` gives a GUI and a graphical console, and `virsh` does everything
else. Nothing here is out-of-tree, licensed, or dependent on a vendor's Linux support.

What the requirements actually need, and where each is met:

| Requirement | Mechanism |
| --- | --- |
| a full VM, not a container (§2, §3) | KVM hardware virtualization |
| cheap to recreate (§3, §13) | a baseline qcow2 to clone from, plus optional autoinstall |
| snapshots (§14) | qcow2 snapshots via `virsh snapshot-*`, BIOS firmware keeps them unrestricted |
| narrow host directory shares (§8) | virtiofs, one `<filesystem>` device per share, read-only supported |
| VM reaches the host model endpoint (§10) | the NAT bridge's host address, `192.168.122.1` |
| outbound Internet (§11) | the same libvirt NAT network |
| runs continuously, survives client disconnects (§14) | `virsh autostart`, the T3 Code server runs as a service |

Rejected:

- **VMware Workstation Pro** — the reason this file was rewritten. Out-of-tree kernel modules that
  break on kernel updates, a vendor account for downloads, and an uncertain future under Broadcom.
  Nothing it does here is unavailable in KVM.
- **VirtualBox** — also out-of-tree modules, slower under load, weaker device model.
- **Incus** — the honest runner-up. Its images, profiles and `incus snapshot` are better ergonomics
  than libvirt XML, and it uses KVM underneath for VMs. It earns its keep when there are many
  instances to manage; for one long-lived VM it adds a management layer over the same hypervisor.
  Revisit if the setup ever grows per-project throwaway VMs.
- **Containers (Docker, LXC, systemd-nspawn)** — a shared kernel is not the boundary the
  specification asks for (§2, §3).

## 2. Check the hardware supports it

```bash
sudo apt install -y cpu-checker
kvm-ok
grep -c svm /proc/cpuinfo        # AMD-V; a count > 0 means it is enabled
```

`kvm-ok` must report that KVM acceleration can be used. If not, enable SVM in the firmware setup.

## 3. Install

```bash
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients virtinst virt-manager \
                    virt-viewer virtiofsd libnss-libvirt
sudo usermod -aG libvirt,kvm "$USER"
```

Log out and back in for the group change.

### Point `virsh` at the system daemon, once

A normal user's `virsh` defaults to `qemu:///session`, a *different* hypervisor instance from the
`qemu:///system` one this setup uses. Without this, `virsh start agent-vm` reports that the domain
does not exist while `virt-manager` shows it running. Set it once in the shell config
([`../common/00-home-environment.md`](../common/00-home-environment.md) symlinks `.bashrc`):

```bash
export LIBVIRT_DEFAULT_URI=qemu:///system
```

It is already in this repo's `.bashrc`. Every `virsh` command in this repo assumes it is set.

Verify:

```bash
systemctl is-active libvirtd            # or virtqemud on a modular-daemon setup
virsh uri                               # must print qemu:///system
virsh list --all                        # must work without sudo
virsh net-list --all                    # 'default' should be active and autostart
```

`libnss-libvirt` lets the host resolve the guest by name, so `ssh agent-vm` works without knowing
its DHCP address. Add the two modules to the `hosts:` line of `/etc/nsswitch.conf`:

```bash
sudo sed -i 's/^hosts:.*/hosts:          files libvirt libvirt_guest mdns4_minimal [NOTFOUND=return] dns/' \
  /etc/nsswitch.conf
getent hosts agent-vm                   # works once the guest is installed and running
```

Name resolution matches the guest's **hostname**, so the guest must be named `agent-vm` at install
time (§5).

Versions in Kubuntu 26.04: libvirt 12.0, QEMU 10.2, virt-manager 5.1, virtiofsd 1.13. The virtiofs
read-only export used in [`../vm/06-shared-folders.md`](../vm/06-shared-folders.md) needs libvirt
≥ 11.0 and virtiofsd ≥ 1.13, so 26.04 is the floor for this setup.

## 4. Storage

Disks stay in libvirt's stock `default` pool, `/var/lib/libvirt/images`. Nothing to define, nothing
to autostart, and no `chmod 711 ~` opening the home directory to every local user just so `qemu`
can traverse it.

```bash
virsh pool-list --all                   # 'default' active and autostart
```

`~/vms/` still exists, but only for host-side text: the ISO, the dumped domain XML and the virtiofs
share definitions ([`../vm/06-shared-folders.md`](../vm/06-shared-folders.md)).

```bash
mkdir -p ~/vms
```

Back up `/var/lib/libvirt/images/agent-vm.qcow2` together with `~/vms/`, see
[`../vm/07-snapshots.md`](../vm/07-snapshots.md).

## 5. Create the VM

The guest is **Kubuntu 26.04 desktop**, same as the host: Plasma is what the eyes are trained on,
and a real desktop in the VM means a browser, a file manager and a graphical editor are there when
an agent's work has to be inspected by hand.

Two decisions that keep the rest of the setup short:

- **Hostname `agent-vm`.** `libnss-libvirt` (§3) resolves the guest by its hostname; `ssh agent-vm`
  and every reference in [`../vm/`](../vm/) depend on it.
- **BIOS firmware, not UEFI.** The guest boots nothing that needs Secure Boot. Choosing SeaBIOS
  drops the `ovmf` package, drops the separate NVRAM file that has to be backed up and restored
  alongside the disk image ([`../vm/07-snapshots.md`](../vm/07-snapshots.md)), and avoids libvirt's
  restrictions on snapshotting a pflash domain.

Download the [Kubuntu ISO](https://kubuntu.org/getkubuntu/) to `~/vms/`.

### The one command

```bash
virt-install --name agent-vm --osinfo detect=on,name=ubuntu24.04 \
  --vcpus 8 --cpu host-passthrough \
  --memory 24576 --memballoon model=virtio,freePageReporting=on \
  --memorybacking source.type=memfd,access.mode=shared \
  --disk size=200,format=qcow2,bus=virtio,discard=unmap \
  --network network=default,model=virtio \
  --boot bios \
  --graphics spice,listen=none,gl.enable=yes \
  --video virtio,accel3d=yes \
  --cdrom "$HOME/vms/kubuntu-26.04-desktop-amd64.iso" --autostart
```

What each choice is for:

| Flag | Reason |
| --- | --- |
| `--vcpus 8 --cpu host-passthrough` | 8 of 24 threads; leaves the host responsive and the model runtime fed |
| `--memory 24576` | desktop, browsers, several agents; the balloon gives idle RAM back |
| `--memorybacking source.type=memfd,access.mode=shared` | **required** for virtiofs shares; adding it later means editing the domain and rebooting |
| `--disk size=200,...,discard=unmap` | 200 GiB sparse qcow2 in the `default` pool; TRIM reaches the host filesystem |
| `--network network=default,model=virtio` | outbound NAT and the host model endpoint on one interface ([`../vm/03-networking.md`](../vm/03-networking.md)) |
| `--boot bios` | SeaBIOS, see above |
| `--graphics spice,listen=none,gl.enable=yes` + `--video virtio,accel3d=yes` | Plasma without a software renderer; virgl needs a local client, and the console is local anyway |
| `--autostart` | the VM comes back with the host (§14) |

`--osinfo detect=on,name=ubuntu24.04` detects from the ISO and falls back to the 24.04 profile
rather than aborting: `osinfo-db` does not always carry the newest release id yet. Check with
`osinfo-query os | grep ubuntu` if curious.

`virt-manager` can do the same thing through **New VM** → Local install media →
**Customize configuration before install**, but every setting above then has to be found in the
GUI, and shared memory in particular is easy to miss. Prefer the command.

### Install the guest

Install Kubuntu normally in the console window that opens: minimal installation, no third-party
drivers, whole virtual disk as one partition, **hostname `agent-vm`**. Continue in
[`../vm/01-bootstrap.md`](../vm/01-bootstrap.md).

To reopen the console later:

```bash
virt-viewer agent-vm
```

### Unattended alternative

The manual installer is the one hand-driven step in an otherwise scripted chain
([`../vm/07-snapshots.md`](../vm/07-snapshots.md) §4). Ubuntu's Subiquity autoinstall removes it:
put an `autoinstall` section in a cloud-init user-data file and pass it to the same command.

```bash
cat > ~/vms/user-data <<'EOF'
#cloud-config
autoinstall:
  version: 1
  identity:
    hostname: agent-vm
    username: CHANGE-ME
    password: "CHANGE-ME-MKPASSWD-HASH"
  ssh:
    install-server: true
    authorized-keys:
      - CHANGE-ME-HOST-PUBLIC-KEY
  packages:
    - kubuntu-desktop
    - qemu-guest-agent
    - spice-vdagent
    - unattended-upgrades
EOF
touch ~/vms/meta-data
```

Generate the password hash with `mkpasswd --method=SHA-512`, and use the host key from
`~/.ssh/id_ed25519.pub`. Then swap `--cdrom` for:

```bash
  --location "$HOME/vms/kubuntu-26.04-desktop-amd64.iso",kernel=casper/vmlinuz,initrd=casper/initrd \
  --cloud-init user-data="$HOME/vms/user-data,meta-data=$HOME/vms/meta-data" \
  --extra-args 'autoinstall ---'
```

This is worth doing the *second* time the VM is built, not the first: it is easier to write the
user-data once the manual install has shown what the answers are. Either way the baseline image
from [`../vm/07-snapshots.md`](../vm/07-snapshots.md) is what makes rebuilds cheap.

## 6. Day-to-day

| Task | Command |
| --- | --- |
| Start / stop | `virsh start agent-vm` / `virsh shutdown agent-vm` |
| Force off | `virsh destroy agent-vm` |
| Serial console | `virsh console agent-vm` (leave with `Ctrl+]`) |
| Graphical console | `virt-manager`, or `virt-viewer agent-vm` |
| Edit hardware | `virsh edit agent-vm` |
| Save the definition | `virsh dumpxml agent-vm > ~/vms/agent-vm.xml` |

## 7. Then

- guest bootstrap: [`../vm/01-bootstrap.md`](../vm/01-bootstrap.md)
- network path from the VM to the host model endpoint:
  [`../vm/03-networking.md`](../vm/03-networking.md)
- sharing selected host directories into the VM:
  [`../vm/06-shared-folders.md`](../vm/06-shared-folders.md)
- snapshots and recreation: [`../vm/07-snapshots.md`](../vm/07-snapshots.md)

## 8. Checklist

- [ ] `kvm-ok` reports KVM acceleration usable
- [ ] `LIBVIRT_DEFAULT_URI=qemu:///system` exported; `virsh uri` confirms it
- [ ] `virsh list --all` works without sudo
- [ ] `default` network active and set to autostart
- [ ] `default` storage pool active at `/var/lib/libvirt/images`
- [ ] `libvirt`/`libvirt_guest` on the `hosts:` line of `/etc/nsswitch.conf`
- [ ] Kubuntu 26.04 desktop installed in the guest, hostname `agent-vm`
- [ ] guest firmware is BIOS, not UEFI (`virsh dumpxml agent-vm | grep -c pflash` returns 0)
- [ ] shared memory backing (`memfd`) present in the domain XML
- [ ] virtio video with 3D acceleration, Spice listen type `none`
- [ ] VM autostarts with the host
- [ ] `getent hosts agent-vm` resolves, and `ssh agent-vm` works from the host
- [ ] domain XML dumped to `~/vms/agent-vm.xml`
