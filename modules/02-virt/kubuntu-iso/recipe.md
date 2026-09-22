# kubuntu-iso recipe

Run this on daily hosts (`xhost`, `bhost`) after `kvm`. Not on guests. On those hosts
`host-sudo-session` provides the cached sudo the script needs.

This module owns only the reusable installer media artifact. It does not create guests, define
isolated networks, choose guest CPU/RAM/disk values, or decide whether the next ISO install is for
Chrome or an agent VM. The Dave overlay reuses the same ISO for both current KVM guests.

## What apply does

- Refuses root and requires cached sudo.
- Requires `~/vms` from `kubuntu-baseline --target daily-host`.
- Downloads `SHA256SUMS`, `SHA256SUMS.gpg`, and the Kubuntu desktop ISO into `~/vms`.
- Verifies the signed checksum file with `/usr/share/keyrings/ubuntu-archive-keyring.gpg`.
- Verifies the ISO checksum before installing it.
- Installs the verified ISO to `/var/lib/libvirt/boot/` with mode `0644`.

The cached ISO stays in `~/vms` so reruns can resume or recheck without downloading from scratch.
The guest-facing copy stays under `/var/lib/libvirt/boot/`, which matches the legacy hypervisor
guide and the Dave Chrome VM overlay.

## Defaults

| Variable               | Default                                                     |
| ---------------------- | ----------------------------------------------------------- |
| `KUBUNTU_ISO_VERSION`  | `26.04.1`                                                   |
| `KUBUNTU_ISO_BASE`     | `https://cdimage.ubuntu.com/kubuntu/releases/26.04/release` |
| `KUBUNTU_ISO_WORK_DIR` | `~/vms`                                                     |
| `KUBUNTU_ISO_DEST_DIR` | `/var/lib/libvirt/boot`                                     |

Override these only when the catalog moves to a new installer release. Keep the catalog and guest
recipes in sync with the ISO filename before changing them.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/02-virt/kubuntu-iso
./apply.sh
```

## Verify

```bash
./verify.sh
```
