# Fold update-tools-timer into home-dotfiles

- created: 2026-09-20
- priority: p3 (low) — user tagged as "later with p3", no urgency
- source: chat with Dave 2026-09-20, after ticking `update-tools-timer` in `2026-09-15-modular-box-setup.md`
- branch: main

Can't we just fold this into home-dotfiles?

## Context

`update-tools-timer` and `home-dotfiles` are tightly coupled: the timer's
`ExecStart=%h/update-tools.sh` needs the script symlink that `home-dotfiles`
owns; `update-tools-timer/apply.sh` even guards for it. Same box coverage
(`Y Y - Y`), same `requires` chain, same `01-home` cluster.

The catalog at `modules/README.md:146` currently says: "`update-tools-timer`
stays its own module (weekly systemd user timer; the script symlink is already
`home-dotfiles`)." That is an explicit split. Folding overrides that call, so
the catalog edit is part of this work, not a follow-up.

## Sketch (do not treat as decided)

1. Catalog first: `modules/README.md` §1 table drops the `update-tools-timer`
   row; the paragraph at line 146 loses the "stays its own module" sentence
   and instead notes that `home-dotfiles` also installs the weekly timer.
2. Merge `modules/01-home/update-tools-timer/` into
   `modules/01-home/home-dotfiles/`:
   - `apply.sh` gains: `mkdir -p ~/.config/systemd/user`, symlink the two unit
     files, `daemon-reload`, `enable --now update-tools.timer`.
   - `verify.sh` gains: two `check_link` calls for the units, and
     `systemctl --user is-enabled` / `is-active` on the timer.
   - `recipe.md` gains a "Timer" subsection.
   - Delete `modules/01-home/update-tools-timer/` and its plan tick line;
     the `home-dotfiles` tick now covers both.
3. Guest baseline (`machines/vm/guest-baseline.sh`) currently ships the
   dotfiles but not this timer. Folding forces "install the timer on guests
   too" — confirm that is the intended live behavior before merging, or gate
   the systemd block on a per-box flag.
4. Re-run apply + verify on `xhost` and `xagt` after the merge.

## Reasons this was left split originally (address in the fold)

- Different failure modes: dotfile symlinks are pure filesystem; timer install
  needs `systemctl --user` reachable and lingering on (`kubuntu-baseline`).
  Splitting kept the systemd surface diagnosable alone. A folded verify still
  needs to report which layer failed.
- Reusability: a future box might want dotfiles without the timer. Currently
  hypothetical.

## Related

- `_plans/open/2026-09-15-modular-box-setup.md` — the parent plan; folding
  removes the `update-tools-timer` tick and collapses it into `home-dotfiles`.

## Observations

- `modules/README.md:146` explicitly rules the current split. Edit that line
  when folding, not after.
- `machines/vm/guest-baseline.sh:183-192` shows the pattern (mkdir, ln -sfn,
  daemon-reload, enable) — reuse it in the folded `apply.sh`.
- No other draft or open plan mentions this fold; nothing to reconcile.

---

Also see `_plans/README.md` and the project `README.md` for any rules that apply.
