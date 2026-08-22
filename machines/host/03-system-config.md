# 03 – Host system configuration

Filesystem layout, backups, packaging, SSH and firewall on the host.

## 1. Filesystem organization

```text
/home/you/
├── Documents/
├── Downloads/
├── Dropbox/
├── projects/            # host-side repos only (this repo, local-llm work)
├── models/
│   ├── 8b/
│   ├── 32b/
│   └── moe/
├── llm-bench/
├── system-info/         # hardware baselines from 01-hardware-validation.md
└── vms/                 # ISOs, domain XML, virtiofs share XML (not the disks)
```

```bash
mkdir -p ~/models ~/llm-bench ~/system-info ~/vms
```

VM **disk images** live in libvirt's stock pool at `/var/lib/libvirt/images`, not under `$HOME`
([05-hypervisor.md](05-hypervisor.md) §4). `~/vms/` holds only the text that describes them.

Large downloaded model files are replaceable, so decide whether they are worth including in backups.

Agent-driven project work happens inside the VM, not here (specification §8). The host keeps this
repo and the local-model work.

## 2. Backups

Configure Linux backups before moving the only copy of important data to Kubuntu.

Prioritize:

```text
~/Documents
~/Dropbox               # if not treated as already-replicated
~/projects
~/.ssh
~/vms                   # domain XML and share definitions; small, and painful to rebuild
important application configuration
recovery material
```

Large GGUF model downloads can usually be excluded because they are reproducible downloads.

VM disk images are backed up separately as snapshots, see
[`../vm/07-snapshots.md`](../vm/07-snapshots.md).

## 3. Flatpak and Snap

- Flatpak: <https://flatpak.org/>
- Flathub: <https://flathub.org/>

A useful packaging rule is:

```text
System/development components → apt
Desktop applications          → apt or Flatpak
GPU/ROCm compute stack        → AMD-supported instructions
```

Kubuntu/Ubuntu may also use Snap. There is no need to remove it preemptively.

Avoid mixing packaging systems for low-level GPU components without a reason.

## 4. SSH

Client:

```bash
sudo apt install -y openssh-client
```

Only install the server if the laptop needs to accept incoming SSH connections:

```bash
sudo apt install -y openssh-server
systemctl status ssh
```

The host's `~/.ssh` is never shared into the VM. Agents get their own purpose-specific keys, see
[`../vm/05-credentials.md`](../vm/05-credentials.md) (specification §12).

If you migrate existing private SSH keys, preserve their permissions. Generating a machine-specific
new key is often preferable.

## 5. Firewall

This is a laptop that joins networks you do not control, so the firewall is on. Not a preference:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo ufw status verbose
```

`ufw enable` survives reboots. libvirt installs its own rules for the guest network in separate
chains, so the NAT bridge keeps working with the firewall up.

The local model server binds to the libvirt bridge `virbr0` rather than `0.0.0.0`, so the VM can
reach inference while the LAN cannot. Rules for that interface are in
[`../vm/03-networking.md`](../vm/03-networking.md).

## 6. System checklist

- [ ] directory layout created
- [ ] backups configured and restore tested, including `~/vms` and `/var/lib/libvirt/images`
- [ ] packaging rule understood
- [ ] SSH client/server state decided
- [ ] `ufw` enabled, default deny incoming
- [ ] unattended security updates active ([`../common/08-auto-updates.md`](../common/08-auto-updates.md))
- [ ] local model endpoint not exposed to the LAN

Next: [04-dev-and-agents.md](04-dev-and-agents.md)
