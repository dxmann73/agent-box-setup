# Bootstrapping

The bootstrap steps moved into the target-specific directories:

| Step | Where |
| --- | --- |
| Install KVM/libvirt, create the VM, install Kubuntu in it | [machines/host/05-hypervisor.md](machines/host/05-hypervisor.md) |
| Guest settings, SPICE console, passwordless sudo, first agent | [machines/vm/01-bootstrap.md](machines/vm/01-bootstrap.md) |
| Unattended patching on both machines | [machines/common/08-auto-updates.md](machines/common/08-auto-updates.md) |
| VM-only SSH keys and API tokens | [machines/vm/05-credentials.md](machines/vm/05-credentials.md) |
| Map host directories into the VM | [machines/vm/06-shared-folders.md](machines/vm/06-shared-folders.md) |

Coming from Windows: start at [machines/migration/](machines/migration/) instead.
