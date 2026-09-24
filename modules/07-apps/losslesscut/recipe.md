# losslesscut recipe

Run this module on the daily host. LosslessCut runs as the upstream Linux AppImage from
<https://github.com/mifi/lossless-cut/releases/latest>.

## Why not the snap

The `losslesscut` snap is built on `core18` and `gnome-3-28-1804`. Its bundled Mesa cannot load
`radeonsi` for current AMD GPUs:

```text
MESA-LOADER: failed to open radeonsi (search paths /snap/losslesscut/<rev>/gnome-platform/usr/lib/x86_64-linux-gnu/dri)
Exiting GPU process due to errors during initialization
```

The main process then crashes with `SIGSEGV`. The AppImage uses the host Mesa and starts cleanly.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/07-apps/losslesscut
./apply.sh
```

## What apply does

- Refuses to run as root. Uses `sudo` only for `apt-get` and `snap remove`.
- Fails fast when LosslessCut is running.
- Installs `libfuse2t64` via `apt-get` only when `dpkg-query` does not report it. AppImage execution
  needs FUSE 2 on Kubuntu.
- Runs [update.sh](update.sh) to download `~/Applications/LosslessCut.AppImage`.
- Copies `config.json` from the snap (`~/snap/losslesscut/current/.config/LosslessCut/`) to
  `~/.config/LosslessCut/` when the AppImage has no settings yet.
- Removes the `losslesscut` snap when installed. snapd keeps an automatic snapshot of the snap data
  (`snap saved`).
- Symlinks `~/.local/share/applications/losslesscut.desktop` to
  [`user-home/applications/losslesscut.desktop`](../../../user-home/applications/losslesscut.desktop).
  The entry keeps `--no-sandbox` from the entry bundled in the AppImage.
- Extracts `usr/share/icons/hicolor/512x512/apps/losslesscut.png` from the AppImage into
  `~/.local/share/icons/hicolor/512x512/apps/`.
- Refreshes `update-desktop-database`, `gtk-update-icon-cache` and `kbuildsycoca6` when those tools
  are present.

## Updates

LosslessCut has no built-in updater. Its "New version!" menu only opens the GitHub release page.

[update.sh](update.sh) asks the GitHub API for the latest release. It compares the SHA-256 of the
local AppImage with the release asset digest and downloads only when they differ. The download is
verified against the digest, then renamed over the old file. A running LosslessCut keeps the old
file until restart.

`~/update-tools.sh` calls `update.sh` in its weekly run when the AppImage is installed. Run it by
hand to update now:

```bash
./update.sh
```

## Verify

```bash
./verify.sh
```

Checks: the AppImage is present and executable; `libfuse2t64` installed; the snap is removed; the
menu entry is the symlink into this repo, passes `desktop-file-validate` and runs the AppImage; the
icon is installed; `update-tools.sh` calls `update.sh`.
