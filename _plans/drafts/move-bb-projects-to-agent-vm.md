# Move BB projects from the host OS onto the agent VM

- created: 2026-09-25
- priority: p1 (high) — user asked to prioritize this with P1
- source: chat, 2026-09-25
- branch: main

The next thing I want to do, so prioritize this with P1. I want to move most of my current BB projects to the HNVM because currently they are running on the host OS, and this may mean that for all the projects that I have in the project manager I want to set up a corresponding project in BB and have this synced as well. I'm not even sure on the other host which I'm setting up the blade 14, how I would, if I would just connect to this, probably I would, but yeah, I need to set this up on the XMG host anyway. And as I said, currently it's pointing to the host via through the host system and it should be pointing to the agent VM.

## Observations

- Open plan `_plans/open/2026-09-15-modular-box-setup.md` still says not to change live boxes before the reconcile phase; this draft asks for live setup on the XMG host.
- Host names (XMG, blade 14) are deployment-overlay material; `docs/specification/agent-box.md` already treats the agent VM as the security boundary.
- Recent commit `9e5143b` (`feat: BB appimage owns everything`) just moved BB install ownership in this repo.

---

Also see `_plans/README.md` and the project `README.md` for any rules that apply.
