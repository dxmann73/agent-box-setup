# update-tools-timer

What: User tool update timer.

Does: Tracks the weekly systemd user timer for managed CLI/tool updates.

Scope boundary: this module owns only the systemd user units
(`user-home/systemd/update-tools.service` and `update-tools.timer`) and the
`systemctl --user enable --now update-tools.timer` step. The `~/update-tools.sh`
script symlink is owned by `home-dotfiles`; this module must not re-create it.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.
