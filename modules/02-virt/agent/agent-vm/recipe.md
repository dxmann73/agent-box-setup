# agent-vm recipe

Run this on a daily host after `kvm`, `kubuntu-iso`, and `isolated-agent-net`. Not on guests. On
daily hosts `host-sudo-session` provides the cached sudo the script needs before creating a domain.

This module owns only the persistent agent execution guest domain: one Kubuntu VM with host CPU
passthrough, shared `memfd` memory for later virtiofs shares, a sparse virtio disk, the isolated
agent network, local-only SPICE graphics, 2D virtio video, and libvirt autostart enabled. It does
not install guest packages, configure SSH or sudo inside the guest, mount shares, authenticate
agent CLIs, enroll BB, create snapshots, or back up disks.

Deployment overlays own concrete values. Source the overlay environment or export these values
before running `apply.sh` or `verify.sh`:

```bash
export AGENT_BOX_VM_HOSTNAME=...
export AGENT_BOX_VM_VCPUS=...
export AGENT_BOX_VM_MEMORY_MIB=...
export AGENT_BOX_VM_DISK_GIB=...
export AGENT_NET_NAME=...
```

Optional:

```bash
export AGENT_BOX_VM_OSINFO=ubuntu24.04
export AGENT_BOX_VM_ISO=/var/lib/libvirt/boot/kubuntu-26.04.1-desktop-amd64.iso
export AGENT_BOX_VM_XML_PATH=~/vms/$AGENT_BOX_VM_HOSTNAME.xml
```

`AGENT_BOX_VM_ISO` should point at the installed `kubuntu-iso` artifact under
`/var/lib/libvirt/boot/`. This module checks that it is readable but does not verify checksums; that
belongs to `kubuntu-iso`.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/02-virt/agent/agent-vm
./apply.sh
```

`apply.sh`:

- refuses to run as root, in a guest, without cached sudo, or over an existing domain;
- checks the referenced isolated agent network exists and is active;
- checks the ISO is readable;
- creates the domain with `virt-install`, `--noautoconsole`, 2D virtio video, local-only SPICE,
  virtio network, shared `memfd` memory, virtio memory balloon, and a sparse virtio qcow2 disk;
- enables domain autostart;
- writes the inactive domain XML to `AGENT_BOX_VM_XML_PATH` for later restore after snapshot work.

Use `./apply.sh --dry-run` to print the `virt-install` command without creating the guest.

## Manual ISO Install

After apply creates the domain, open a viewer and complete the Kubuntu desktop install manually.
Use the deployment's hostname and login policy for the agent guest. Closing `virt-viewer` should
leave the domain running.

This module deliberately stops at domain creation. The next guest module owns console SSH/sudo
bootstrap, and later modules own guest integration, shares, snapshots, credentials, BB enrollment,
and agent tooling checks.

## Verify

```bash
./verify.sh
```

`verify.sh` checks the inactive domain definition against the exported values, including vCPU
count, memory, isolated agent network, disk size, shared `memfd` memory, virtio memory balloon,
local-only SPICE, 2D virtio video, autostart enabled, and the saved XML path. If the domain is
running, it also checks that the live XML still has local-only SPICE and 2D virtio video.

## Catalog Alignment

The legacy host guide used libvirt's stock `default` network for the agent VM. The catalog now says
the agent VM uses `isolated-agent-net`; this recipe follows the catalog and expects `AGENT_NET_NAME`
to name that network. Host services such as local-model endpoints stay behind Tailscale policy, not
bridge exceptions.

## Simplification Candidates

- `agent-vm` and `chrome-vm` now share a create-and-verify structure. Consider extracting common
  environment validation, domain XML parsing, and disk-size helpers after both modules have settled.
- `AGENT_BOX_VM_*` preserves existing overlay names. If more deployments appear, consider adding a
  generic `AGENT_VM_*` alias layer in the scripts while keeping the old names as compatibility
  inputs.
