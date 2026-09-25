# chrome-vm-launcher recipe

Run this module on the daily host that owns the browser guest, after `chrome-vm` and
`guest-integration`.

This is not a URL-opening bridge. The deployment overlay explicitly keeps host `http`, `https`,
`webcal`, and `text/html` handlers on the stock host browser so local callback flows still land on
the host. This module installs only the pinned VM opener.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/02-virt/chrome/chrome-vm-launcher
./apply.sh
```

For a deployment that wants to assert a specific host browser as the default handler, export its
desktop file before applying:

```bash
CHROME_VM_LAUNCHER_HOST_BROWSER_DESKTOP=firefox_firefox.desktop ./apply.sh
```

## What apply does

- Symlinks `show-chrome-vm.sh` into `~/.local/bin/`.
- Symlinks `chrome-vm.desktop` into `~/.local/share/applications/`.
- Symlinks the Chrome icon `google-chrome-vm.png` into `~/.local/share/icons/hicolor/256x256/apps/`.
  It is Chrome's own `product_logo_256.png`; the host has no Chrome package to take it from.
- Refreshes desktop caches when the KDE tools are present.
- Optionally reasserts the host browser handlers when
  `CHROME_VM_LAUNCHER_HOST_BROWSER_DESKTOP` is set.

The launcher starts `chrome-vm` if needed, waits for qemu-guest-agent, and attaches `virt-viewer`
unless a viewer process is already present. It exits with usage text when any URL or other argument
is passed.

## Verify

```bash
./verify.sh
```

With an expected host browser:

```bash
CHROME_VM_LAUNCHER_HOST_BROWSER_DESKTOP=firefox_firefox.desktop ./verify.sh
```

Checks: launcher, desktop, and icon symlinks point at this module; the entry uses the Chrome
icon; the desktop entry validates when `desktop-file-validate` is installed; URL arguments are
rejected; `chrome-vm.desktop` is not the default handler for host web URLs or HTML.
