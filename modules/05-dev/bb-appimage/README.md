# bb-appimage

What: BB shared control-plane AppImage.

Does: Wires the host AppImage into the session: FUSE 2 package, KDE autostart entry,
application-menu entry and menu icon. The AppImage bundles the BB UI, server, and host daemon.
Enable the built-in Provider usage plugin after first launch (`bb plugin enable provider-usage`).

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `./apply.sh`

Verify: `./verify.sh`

Downloading `~/Applications/bb.AppImage` stays manual (GitHub release, then BB's own updater
replaces the file in place). `apply.sh` fails fast when it is missing.
