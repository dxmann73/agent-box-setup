# Windows to Linux migration

One-time move of the XMG EVO 14 (E25) from Windows to Kubuntu 26.04 LTS, initially as dual boot.

**This directory is disposable.** Once Windows is gone and the host is stable, delete it — nothing
in [`../host/`](../host/), [`../vm/`](../vm/) or [`../common/`](../common/) depends on it. Keep it
that way: no permanent host or VM instruction belongs in here, and no dual-boot or migration
instruction belongs out there. WSL notes in `common/` are exempt — WSL is a supported host variant.

The invariant is grep-able:

```bash
grep -rilE 'bitlocker|fast startup|dual.?boot|windows partition|shrink windows|ntfs' host/ vm/ common/   # must stay empty
```

## Order

| File | Scope |
| --- | --- |
| [01-windows-preparation.md](01-windows-preparation.md) | Backup, firmware, Fast Startup, disk planning, installer USB |
| [02-kubuntu-installation.md](02-kubuntu-installation.md) | Live test, install, encryption, first boot, Secure Boot |
| [03-staging.md](03-staging.md) | Sequencing rules while both systems coexist |

## Sequence

```text
Windows
   │
   ├── backup
   ├── record BitLocker key
   ├── update BIOS
   ├── disable Fast Startup
   └── shrink Windows partition
           │
           ▼
Create Kubuntu USB
           │
           ▼
Test live environment
           │
           ▼
Install Kubuntu dual boot
           │
           ▼
Update stock Kubuntu
           │
           ▼
host/01 – validate AMDGPU / Mesa / Vulkan / laptop hardware
           │
           ▼
host/02 – install daily applications
           │
           ▼
host/03 – filesystem, backups, SSH, firewall
           │
           ▼
host/04 – development toolchain and agents
           │
           ▼
Test Steam games, Office and video workflow
           │
           ▼
local-llm/ – Vulkan baseline, then ROCm
           │
           ▼
host/05 + vm/ – hypervisor and agent VM
           │
           ▼
After several weeks: decide whether Windows is still needed
```

## References

- Kubuntu download: <https://kubuntu.org/getkubuntu/>
- Ubuntu releases: <https://releases.ubuntu.com/>
- XMG support: <https://www.xmg.gg/en/support/>
