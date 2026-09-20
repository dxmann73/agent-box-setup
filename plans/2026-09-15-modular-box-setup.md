# Modular box setup — implementation plan

The target state lives in the catalog:

[2026-09-14-modular-machine-catalog-design.md](./2026-09-14-modular-machine-catalog-design.md)

This file tracks only the remaining implementation phases. Do not duplicate catalog
ticks, values, module definitions, operator schedule, or live-drift details here. If a
catalog tick or value changes, stop and edit the catalog first.

## Guardrails

- Finish one phase before starting the next.
- Keep `machines/` in place until the cutover phase.
- Keep `agents/` and `user-home/` as payload trees.
- Do not change live boxes before the reconcile phase.
- Recipes must not embed secrets.

## 1. Scaffold

Create `modules/00-os` … `modules/07-apps`. One directory per catalog module:
`modules/<section>/<module-id>/README.md`.

README is short: what the module is, what it does, plus typ / sit / scp / requires / ticks (or
“see catalog”). No install steps.

Leave `machines/` in place. No extra modules.

**Done:** every catalog row has a README; READMEs have no how-to.

## 2. Recipes

Put the how-to in scripts / config / unit files in that directory. Keep the README as short as
possible; do not grow it into a guide.

Each module also gets its own verify (this tick only). Daily-host bootstrap (`START-HERE` on
`xhost` / `bhost`) runs `host-sudo-session` before rootful module work.

Do not delete `machines/` yet. Dual tree is expected. Do not change live boxes.

**Done:** every catalog module has a short README, apply artifacts, and a per-tick verify.

## 3. Cutover

Step by step, one module at a time. Virt guest modules may move as a section if KVM, nets, and ISO
are too coupled to move safely one-by-one.

For each slice:

1. Run that module’s verify on a box that ticks it.
2. Delete the overlapping `machines/` text.
3. Update `README.md`, `START-HERE.md`, and `AGENTS.md` as needed.

Replace `verify-setup.sh` with a thin runner: given a box id, run each ticked module’s verify.
`--host`, `--vm`, and `--bootstrap|--operational|--full` are not the source of truth.

Delete spec §4 standalone VM BB fallback when the BB slice cuts over.

**Done:** `machines/` bundles gone; no giant verify script; per-box verification follows catalog
ticks; spec does not mention the VM npm BB server.

## 4. Reconcile live boxes

Last. After phase 3, apply the catalog’s current live-vs-catalog table. Do not use this phase to
change ticks.

**Done:** the live-vs-catalog table is empty; each drifted tick’s verify matches the catalog on the
live boxes.
