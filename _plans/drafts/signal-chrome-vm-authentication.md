# Install and authenticate Signal app on Chrome VM

- created: 2026-09-25
- priority: p1 (high) — user explicitly raised this to P1 on 2026-09-25
- branch: main

Install the Signal app on the Chrome VM, then log in and authenticate it. This is part of the Chrome VM authentication loop.

To retract on this, I misunderstood. So there should be two things. The first is the update Chrome VM from Clean Snapshot that was there. It is pretty high priority. I would say P1. And then there's the install, the Signal app. This is a separate one. It needs to be authenticated. That's right. And it should be done after the Chrome auth has actually been done. So just put a reference in the plan that we only finalize, have finalized the Chrome authentication loop when signal is authenticated as well. And then I will pull a new snapshot and use this as the clean one.

## Related

- `_plans/drafts/update-chrome-vm-from-clean-snapshot.md` — complete the Chrome VM refresh and base authentication before Signal.

## Observations

- `modules/06-cred/personal-browser-logins` already defines a Chrome-guest authentication step; Signal should join that authentication-loop scope.
- Do not mark the Chrome authentication loop finalized until Signal is installed and authenticated; then create the replacement clean snapshot.

---

Also see `_plans/README.md` and the project `README.md` for any rules that apply.
