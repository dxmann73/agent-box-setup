# virtiofs-desktop-share recipe

Run the host side on a daily host after `chrome-vm` exists. Run the guest side inside the browser
guest after `guest-ssh-sudo-bootstrap` has passwordless sudo working.

This module owns only the Desktop virtiofs share:

- host side: create a libvirt filesystem device with a `desktop` mount tag, attach it to the Chrome
  VM domain, and refresh the saved inactive domain XML;
- guest side: mount that tag on the guest user's `~/Desktop` and persist it in `/etc/fstab` with
  `nofail`;
- verify both sides.

It does not install Chrome, set browser login state, pass USB devices, configure clipboard, create
snapshots, or back up disks.

## Values

Deployment overlays own concrete paths and names. Export these values before running either mode:

```bash
export CHROME_VM_DOMAIN=chrome-vm
export DESKTOP_SHARE_HOST_PATH="$HOME/Desktop"
```

Optional:

```bash
export DESKTOP_SHARE_TAG=desktop
export DESKTOP_SHARE_GUEST_PATH="$HOME/Desktop"
export DESKTOP_SHARE_XML_PATH="$HOME/vms/share-desktop.xml"
export CHROME_VM_XML_PATH="$HOME/vms/$CHROME_VM_DOMAIN.xml"
export CHROME_VM_EXPECTED_HOSTNAME=chrome-vm
```

The share is intentionally read-write. The host path must be a narrow Desktop directory, never
`$HOME`, a document tree, a synced data root, or a credential directory. Files written by the guest
are host files; VM snapshots do not roll them back.

## Apply

On the host:

```bash
cd ~/projects/agent-box-setup/modules/02-virt/chrome/virtiofs-desktop-share
./apply.sh --host
```

`apply.sh --host`:

- refuses to run as root or inside a VM;
- checks the Chrome VM domain exists and has shared `memfd` memory backing;
- writes `DESKTOP_SHARE_XML_PATH`;
- attaches the filesystem device to the persistent domain definition, and to the live guest when it
  is running;
- writes the updated inactive domain XML to `CHROME_VM_XML_PATH`.

Use `./apply.sh --host --dry-run` to print the generated filesystem XML without attaching it.

Inside the browser guest:

```bash
cd ~/projects/agent-box-setup/modules/02-virt/chrome/virtiofs-desktop-share
./apply.sh --guest
```

`apply.sh --guest`:

- refuses to run as root, outside a VM, without passwordless sudo, or on the wrong hostname;
- refuses to hide existing local Desktop files unless `DESKTOP_SHARE_ALLOW_NONEMPTY=1` is set;
- mounts `DESKTOP_SHARE_TAG` at `DESKTOP_SHARE_GUEST_PATH`;
- adds a single `virtiofs` fstab line with `rw,nofail`.

## Verify

On the host:

```bash
./verify.sh --host
```

Inside the browser guest:

```bash
./verify.sh --guest
```

Host verification checks the domain XML, saved filesystem XML, source directory, shared memory
backing, and live XML when the guest is running. Guest verification checks the hostname guard,
mountpoint, filesystem type, mount tag, read-write mount options, and fstab persistence.

## Operational Checks

After both sides pass, prove the actual browser workflow manually:

- create a small test file in the guest Desktop and see it on the host Desktop;
- delete the test file from the host;
- set Chrome's download directory to the guest Desktop and confirm a download lands on the host
  Desktop.

Do not attach broader host paths to the browser guest to make downloads easier.

## Simplification Candidates

- `virtiofs-user-data-shares` will need the same XML generation and fstab handling with different
  safety policy. Consider extracting shared helper code only after that module exists, so the Chrome
  Desktop exception remains obvious.
- The Chrome download-directory check remains manual because `chrome-vm-packages` is a separate
  module and this tick does not require Chrome to be installed yet. If a later Chrome policy module
  appears, move that check there rather than adding a Chrome dependency here.
