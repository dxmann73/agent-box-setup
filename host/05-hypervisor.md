# 05 – Hypervisor and agent VM

The host runs the hypervisor; the VM it creates is the security boundary for all agent work
(specification §3).

## 1. Install VMware Workstation Pro

Get
[VMware Workstation Pro](https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion)

Note: when the download page says "temporarily unavailable", try another browser.

## 2. Create the VM

Get the [Ubuntu ISO](https://ubuntu.com/download/desktop) and create the guest with:

```text
2 processors × 8 cores
4 GB memory
NAT networking
40 GB disk, single file, allocate as needed
```

Memory and disk are the two values worth revisiting: several concurrent agents plus a browser and
build processes outgrow 4 GB quickly.

Keep VM disk images under `~/vms/` so backups can treat them as one unit.

## 3. Host-side tooling

```bash
sudo apt install -y open-vm-tools open-vm-tools-desktop
```

Reboot if anything was installed.

## 4. Then

- guest OS installation and bootstrap: [`../vm/01-bootstrap.md`](../vm/01-bootstrap.md)
- network path from the VM to the host model endpoint:
  [`../vm/04-networking.md`](../vm/04-networking.md)
- sharing selected host directories (e.g. Dropbox tax folder) into the VM:
  [`../vm/06-shared-folders.md`](../vm/06-shared-folders.md)
- snapshots and recreation: [`../vm/07-snapshots.md`](../vm/07-snapshots.md)

## 5. Checklist

- [ ] VMware Workstation Pro installed and licensed
- [ ] Ubuntu ISO downloaded
- [ ] VM created with agreed CPU/memory/disk
- [ ] `open-vm-tools` present on the host
- [ ] VM images live under `~/vms/`
