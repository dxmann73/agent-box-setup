# Update Chrome VM from the clean snapshot

- created: 2026-09-22
- priority: p3 (low) — no urgency signal in the text
- branch: main

I want to update the chrome vm from the clean snapshot, a lot of the logins have not been done, also I'd like to update chrome.

## Observations

- Open plan `_plans/open/2026-09-15-modular-box-setup.md` still has unchecked `chrome-vm`, `chrome-vm-packages`, `vm-snapshots`, `personal-browser-logins`, and `bitwarden-chrome`; those are module-cutover items, separate from this live refresh.
- Draft `_plans/drafts/vibe-typer-update-check-and-assisted-updater.md` notes `chrome-vm-clean-reminder.sh` (notify-send bug in dave.box-setup); that reminds about a clean snapshot and does not perform this refresh.
- Working tree on `main` is dirty: KVM module files and the modular-box-setup plan are mid-edit.

---

Also see `_plans/README.md` and the project `README.md` for any rules that apply.
