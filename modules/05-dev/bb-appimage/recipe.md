# bb-appimage recipe

Run this module on the host that owns the BB control plane (`xhost`). The host runs the official
Linux desktop AppImage; it bundles the BB UI, server and host daemon. The agent VM is only an
enrolled execution machine (`bb-enroll-execution-machine`).

Full prose, VM enrollment and shared-access notes live in
[`machines/common/05-bb.md`](../../../machines/common/05-bb.md). This recipe is the repeatable part.
For AppImage updates and failed-start recovery, see [appimage-updates.md](appimage-updates.md).

## Prerequisite: the AppImage itself

The download is manual because BB ships releases on GitHub and the built-in updater then replaces
the file in place. `apply.sh` does not download it and fails fast when it is missing.

```bash
mkdir -p ~/Applications
# download the current x86_64.AppImage from
# https://github.com/get-bb/bb/releases/latest
mv ~/Downloads/bb-*-x86_64.AppImage ~/Applications/bb.AppImage
chmod +x ~/Applications/bb.AppImage
```

## Apply

```bash
cd ~/projects/agent-box-setup/modules/05-dev/bb-appimage
./apply.sh
```

## What apply does

- Refuses to run as root; every path it touches lives under `$HOME`.
- Fails fast when `~/Applications/bb.AppImage` is missing or not executable.
- Installs `libfuse2t64` via `apt-get` only when `dpkg-query` does not report it. AppImage execution
  needs FUSE 2 on Kubuntu.
- Writes `~/.config/autostart/bb.desktop` with `Exec=$HOME/Applications/bb.AppImage` so KDE starts
  BB after login.
- Symlinks `~/.local/share/applications/bb.desktop` to
  [`user-home/applications/bb.desktop`](../../../user-home/applications/bb.desktop) so BB appears in
  the application menu and in KRunner.
- Extracts `usr/share/icons/hicolor/1024x1024/apps/bb.png` from the AppImage into
  `~/.local/share/icons/hicolor/1024x1024/apps/bb.png`. The desktop entry references `Icon=bb`, and
  nothing else on the system ships that icon.
- Refreshes `update-desktop-database`, `gtk-update-icon-cache` and `kbuildsycoca6` when those tools
  are present.

The menu entry is the part that used to be missing. `machines/common/05-bb.md` only said to accept
AppImage menu integration if the desktop offers it. Kubuntu does not offer it without `appimaged`,
so the entry never appeared and `bb` in KRunner started the CLI (`~/.local/bin/bb`) instead, which
prints help and exits 1.

The desktop entry keeps `Icon=bb` and `StartupWMClass=bb`, matching the entry bundled inside the
AppImage. `StartupWMClass` is what lets KDE map the running window to the launcher on Wayland.

## Post-install, once the app runs

After first launch, use the BB settings UI to set the sidebar organization to project and enable the
Provider usage plugin.

## Verify

```bash
./verify.sh
```

Checks: the AppImage is present and executable; `libfuse2t64` installed; autostart entry present and
pointing at the AppImage; the menu entry is the symlink into this repo and passes
`desktop-file-validate`; the `bb` icon is installed.

`verify.sh` requires BB to be running. It checks the health endpoint and expected BB processes. It
does not start or stop BB.
