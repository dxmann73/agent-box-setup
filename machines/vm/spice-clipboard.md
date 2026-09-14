# SPICE clipboard on Plasma Wayland

SPICE's guest agent consumes the X11 clipboard. A Plasma Wayland guest can receive clipboard data
but fail to export copies made by native Wayland applications. Install the bridge from the host,
after guest SSH and sudo work:

```bash
ssh VM_NAME 'bash -s' \
  < ~/projects/agent-box-setup/machines/vm/install-spice-clipboard-sync.sh
```

The installer adds `wl-clipboard` and `xclip` when missing, installs root-owned helpers and a user
service, and enables Klipper's image handling (`IgnoreImages=false`). Images consequently
participate in Klipper's clipboard history. It does not install a repository or agent tooling in the
guest.

The service listens for Klipper changes and exports plain text or PNG data to the X11 selection. It
compares the existing selection before writing to prevent clipboard feedback. Temporary payloads
stay in the user's runtime directory and are deleted after each export; content is not logged. Other
clipboard formats are not exported by this helper.

Do not run the older text-only `klipper-clipboard-sync` service alongside this bridge. Choose one
bridge for the guest. This installer is for Plasma Wayland; it requires a running Klipper session
when installed. It uses Klipper notifications because the distribution's `wl-paste --watch` may
require a data-control protocol that the compositor does not expose.

## Verify

```bash
systemctl --user is-active spice-clipboard-sync.service
journalctl --user -u spice-clipboard-sync.service --since '5 minutes ago'
```

Focus the viewer on the host before testing transfers. Verify distinct text and PNG images in both
directions, including copies from a native Wayland application. Compare decoded image pixels, not
PNG file bytes, because clipboard tools may re-encode images. Repeat after guest restart.

Also verify a real screenshot paste into the intended browser application. A running service or a
successful text transfer alone does not prove image support.
