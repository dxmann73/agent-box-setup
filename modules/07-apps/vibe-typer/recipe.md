# vibe-typer recipe

Run on a catalog-ticked daily host. This module consumes the deployment overlay's launcher, desktop
entry, and user-systemd reminder. It intentionally does not track a vendor AppImage URL or replace
executables automatically.

## Download, review, and apply

Download the current AppImage from the vendor, review it, then place it at
`~/Applications/VibeTyper.AppImage` and make it executable. Point `--overlay` at the identity
directory supplied by the deployment overlay:

```bash
chmod +x ~/Applications/VibeTyper.AppImage
cd ~/projects/agent-box-setup/modules/07-apps/vibe-typer
./apply.sh --overlay ~/projects/dave.box-setup/agent-box/identity
```

The script refuses to overwrite non-symlinked user files. It symlinks the overlay-owned launcher,
desktop entry, and reminder units; reloads the user systemd manager; and enables the weekly
reminder. The reminder asks the user to review a new download before replacing the AppImage.

## Verify

```bash
./verify.sh --overlay ~/projects/dave.box-setup/agent-box/identity
```

The verifier checks the AppImage, exact overlay symlinks, desktop-entry validity when the validator
is available, and the enabled reminder timer. It does not start the microphone-capable application.
