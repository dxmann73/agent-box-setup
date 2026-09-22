# VibeTyper update check, persistent notification, assisted updater

- created: 2026-09-21
- priority: p2 (medium) — user actively bothered by vanishing reminder and no update path; nothing broken
- branch: main

I have just seen the update messages. They went by and disappeared again and I don't see them in
the notifications pop up in Kubuntu. So I think something needs changing there. And so, for the
Vibe Typer app, it says like check for updates and I don't even know how to check for updates. So
how do I proceed here

The current mechanism is in the repo. There's a module that reminds the user that the user needs
to take care of updates because automatic updates are not installed. A couple of apps, I think two
of them right now are in this schedule and Vibe Typer is one of them. And I see the notification,
but just for a very short time. Then there's a progress bar running backwards and it disappears.

Option B and do a real version check. So scrape the downloads page, compare to the binary and only
notify when there's a div. And then please run this daily. Also, I would like to have an automated
update process or at least assisted. So the notification should include what I need to do, and
what I need to do should be a script. I wonder if we could automate this.

Can you check the website what they say about updating their app? Because an app image seems to be
like a cumbersome way to do it.

## Context gathered in the capture session

- Reminder script: `~/.local/bin/vibe-typer-update-reminder.sh` (symlink target
  `~/projects/dave.box-setup/agent-box/identity/vibe-typer-update-reminder.sh`).
- Unit files: `vibe-typer-update-reminder.service` / `.timer` under
  `~/projects/dave.box-setup/agent-box/identity/systemd/`, symlinked into
  `~/.config/systemd/user/`. Timer is `OnCalendar=weekly`, `Persistent=true`.
- Current `notify-send` call has no `-u`, no `-t`, no `--hint=int:transient:0`, so KDE Plasma
  auto-dismisses and (per user) it never lands in the notification history.
- AppImage lives at `~/Applications/VibeTyper.AppImage` (~136 MB, Electron).
- AppImage does not accept `--version` — Electron shim just prints a deprecation warning and
  starts the app. Version must come from another source (see "Version source" below).
- `vibe-typer.service` runs the AppImage and is currently active — an in-place replace while
  running would break the process.
- Sibling reminder with the same pattern: `chrome-vm-clean-reminder.service` — same
  `notify-send` shape, same disappearing behaviour.
- `https://vibetyper.com/downloads` publishes one Linux artifact: portable `.AppImage`. The
  downloads page and FAQ contain no self-update guidance and no versioned filename. The download
  URL scraped is `https://vibetyper.com/downloads/linux/post-download` (a redirect endpoint, not
  a versioned file).
- Website says nothing about updates on the downloads page or FAQ. Need to check other pages
  (changelog, blog, GitHub, `/updates`, release feed) — not yet done in this capture session.

## Work to do (not yet designed)

1. Notification: change reminder script(s) to `notify-send -t 0 --hint=int:transient:0` so KDE
   keeps them on screen until dismissed and in notification history.
2. Version source: figure out where the current installed AppImage version can be read from
   (extracted `resources/app.asar` `package.json`, or the About dialog / log file). Options:
   - Extract AppImage once at install time and record version in `~/.local/state/vibe-typer/version`.
   - Read `resources/app.asar` metadata without full extract (asar tool or offset read).
   - Query the running instance if it exposes it (unknown).
3. Latest-version source: scrape `https://vibetyper.com/downloads` (or the `post-download`
   endpoint) for the served filename / redirect target; fall back to a changelog or release
   feed if one exists. Investigate whether the vendor publishes a JSON manifest or an
   `appimageupdate` `.zsync` (VibeTyper does not ship one today — needs re-verification).
4. Daily timer: change `vibe-typer-update-reminder.timer` from `OnCalendar=weekly` to daily.
   Only notify when installed != latest. Silent when equal.
5. Notification body: include the exact command to run to update, e.g.
   `Run: vibe-typer-update.sh` — the body must reference an actual script that exists on PATH.
6. Assisted updater script `vibe-typer-update.sh`:
   - `systemctl --user stop vibe-typer.service`
   - Download new AppImage to a temp file over HTTPS.
   - Show size + SHA-256 to the user and require confirmation (assisted mode). Provide a
     `--yes` flag for full auto.
   - `chmod +x` + atomic `mv` into `~/Applications/VibeTyper.AppImage`.
   - Record new version to state file.
   - `systemctl --user start vibe-typer.service`.
   - On any failure, roll back to the previous AppImage kept as `.prev`.
7. Question: does the user want full auto (unattended replace on a schedule) or assisted only
   (script runs on demand from the notification)? User's own words: "an automated update
   process or at least assisted" — leaning auto, wants at minimum assisted. Decide during
   refinement.
8. Apply the same notification fix to `chrome-vm-clean-reminder.sh` (same bug, different
   payload).

## Cross-repo note

The scripts and units live in `~/projects/dave.box-setup/agent-box/identity/` — a different
repo than this one (`agent-box-setup`). Implementation edits happen there. This plan lives here
because this is where `_plans/` exists and where the capture happened.

## Related

(none — scan of `_plans/drafts/`, `_plans/next/`, `_plans/open/` found no overlap)

## Observations

- Repo is clean on branch `main`; no in-flight work to collide with.
- The `dave.box-setup` repo is the actual code target; check its state before starting.
- `chrome-vm-clean-reminder.sh` has the identical `notify-send` bug and should be fixed in the
  same pass.

---

Also see `_plans/README.md` and the project `README.md` for any rules that apply.
