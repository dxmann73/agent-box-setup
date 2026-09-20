# update-tools-timer recipe

Weekly systemd **user** timer that runs `~/update-tools.sh`. That script is symlinked into `$HOME`
by [`home-dotfiles`](../home-dotfiles/recipe.md); this module does not create it.

The timer runs without an active login session because `kubuntu-baseline` already turns lingering on
(`loginctl enable-linger`). If lingering is off, `systemctl --user list-timers` shows no run until
the next login — check `kubuntu-baseline` first, do not add a linger step here.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/01-home/update-tools-timer
./apply.sh
```

`apply.sh` is idempotent:

- Ensures `~/.config/systemd/user/` exists.
- Symlinks `user-home/systemd/update-tools.service` and `update-tools.timer` from the repo into
  that directory (`ln -sfn`, so a stale link is repointed).
- `systemctl --user daemon-reload`.
- `systemctl --user enable --now update-tools.timer`.

It does not run `~/update-tools.sh` inline. Run that once by hand the first time so failures show
up before the timer fires:

```bash
~/update-tools.sh
```

## What it enables

- `update-tools.service` — oneshot, `ExecStart=%h/update-tools.sh`.
- `update-tools.timer` — `OnCalendar=weekly`, `Persistent=true`.

Both unit files live under [`user-home/systemd/`](../../../user-home/systemd/) and are edited there,
not copied.

## Verify

```bash
./verify.sh
```

Checks the two unit symlinks resolve into the repo payload, the timer is enabled, and the timer is
active. Read the last run's log with:

```bash
journalctl --user -u update-tools.service -n 50
```

## Scope

- In: install and enable the user timer + its service unit.
- Out: `~/update-tools.sh` symlink (home-dotfiles), lingering (kubuntu-baseline), apt / flatpak
  auto-updates (future modules carved from `machines/common/08-auto-updates.md`), BB updates (not
  automated on purpose).
