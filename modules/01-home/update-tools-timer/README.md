# update-tools-timer

What: User tool update timer.

Does: Installs and enables the weekly systemd **user** timer that runs
`~/update-tools.sh` (managed CLI/tool updates).

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `./apply.sh`

Verify: `./verify.sh`

Scope boundary: this module owns only the systemd user units
(`user-home/systemd/update-tools.service` and `update-tools.timer`) and the
`systemctl --user enable --now update-tools.timer` step. The
`~/update-tools.sh` script symlink is owned by `home-dotfiles`; this module
must not re-create it. Lingering (`loginctl enable-linger`) is owned by
`kubuntu-baseline`.
