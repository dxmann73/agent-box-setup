# chrome-vm recipe

Run this on a daily host after `kvm`, `kubuntu-iso`, and `isolated-browser-net`. Not on guests. On
daily hosts `host-sudo-session` provides the cached sudo the script needs for the QEMU render-group
check.

This module owns only the browser guest domain shape: one persistent Kubuntu VM with SPICE GL,
virtio 3D video, virtio network, SPICE audio, a single sparse disk, and autostart disabled. It does
not install guest packages, configure SSH or sudo inside the guest, add host launchers, mount shares,
attach camera devices, create snapshots, or set browser logins.

Deployment overlays own concrete values. Source the overlay environment or export these values
before running `apply.sh` or `verify.sh`:

```bash
export CHROME_VM_DOMAIN=...
export CHROME_VM_NETWORK=...
export CHROME_VM_VCPUS=...
export CHROME_VM_MEMORY_MIB=...
export CHROME_VM_DISK_GIB=...
export CHROME_VM_ISO=...
```

Optional:

```bash
export CHROME_VM_OSINFO=ubuntu24.04
export CHROME_VM_RENDER_NODE=/dev/dri/renderD128
export CHROME_VM_XML_PATH=~/vms/$CHROME_VM_DOMAIN.xml
```

`CHROME_VM_ISO` should point at the installed `kubuntu-iso` artifact under
`/var/lib/libvirt/boot/`. This module checks that it is readable but does not verify checksums; that
belongs to `kubuntu-iso`.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/02-virt/chrome/chrome-vm
./apply.sh
```

`apply.sh`:

- refuses to run as root, in a guest, without cached sudo, or over an existing domain;
- checks the referenced isolated browser network exists and is active;
- checks the ISO and render node are readable;
- makes sure `libvirt-qemu` is in the `render` group for SPICE GL;
- creates the domain with `virt-install`, `--noautoconsole`, SPICE GL, virtio 3D video, SPICE
  audio, virtio network, and a sparse virtio qcow2 disk;
- disables domain autostart;
- applies the SPICE compression edits used by the legacy overlay;
- writes the inactive domain XML to `CHROME_VM_XML_PATH` for later restore after snapshot work.

Use `./apply.sh --dry-run` to print the `virt-install` command without creating the guest.

## Manual ISO Install

After apply creates the domain, open a viewer and complete the Kubuntu desktop install manually.
Use the deployment's hostname and login policy for the browser guest. Closing `virt-viewer` should
leave the domain running.

This module deliberately stops at domain creation. The next guest modules own console SSH/sudo
bootstrap and integration packages. Browser packages and personal browser logins are later Chrome
modules.

## Verify

```bash
./verify.sh
```

`verify.sh` checks the inactive domain definition against the exported values, including vCPU count,
memory, network, disk size, SPICE GL, virtio 3D video, audio, autostart disabled, render-group
access, and the saved XML path. If the domain is running, it also checks that the live XML still has
SPICE GL and virtio 3D enabled.

## Simplification Candidate

The future `agent-vm` role will need a similar create-and-verify structure with different video,
network, and resource values. After both role modules exist, consider extracting shared domain XML
helpers while keeping role-specific graphics and lifecycle choices in each module.
