# Bootstrapping

The bootstrap steps moved into the target-specific directories:

| Step | Where |
| --- | --- |
| Install KVM/libvirt, create the VM, install Kubuntu in it | [host/05-hypervisor.md](host/05-hypervisor.md) |
| Guest settings, SPICE console, passwordless sudo, first agent | [vm/01-bootstrap.md](vm/01-bootstrap.md) |
| Unattended patching on both machines | [common/08-auto-updates.md](common/08-auto-updates.md) |
| VM-only SSH keys and API tokens | [vm/05-credentials.md](vm/05-credentials.md) |
| Map host directories into the VM | [vm/06-shared-folders.md](vm/06-shared-folders.md) |

Coming from Windows: start at [migration/](migration/) instead.
