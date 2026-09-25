# Remove CLAUDE.md because Claude Code reads AGENTS.md

- source: `_plans/drafts/remove-claude-md-for-agents-md.md`
- priority: p2 — user marked this p2 after an earlier p1 note
- status: open
- written: 2026-09-25

## Goal

Stop shipping `CLAUDE.md` shims. Claude Code v2.1.277+ reads `AGENTS.md` on its own when no
`CLAUDE.md`, `.claude/CLAUDE.md`, or `CLAUDE.local.md` sits in the working directory or above it.
This setup still creates those shims, and the home one blocks that fallback for every project
under `$HOME`.

Target state:

- `~/AGENTS.md` stays the global rule file, including the troubleshooting rule moved out of
  `~/.claude/CLAUDE.md`. `~/CLAUDE.md` and `~/.claude/CLAUDE.md` are both gone.
- Every `CLAUDE.md` under `~/projects` that is a symlink to `AGENTS.md`, or a symlink whose
  target is missing, is gone. The walk is the source of truth. Do not freeze a repo list.
- `new-project` does not create one. `sync-repo-setup` removes a symlink shim and stops on a real
  `CLAUDE.md`.
- `agent-config` apply and verify match that state on daily hosts and the agent VM.
- User settings keep the built-in default `instructionFiles` value `claude-md-or-agents-md`.

## Non-goals

- Do not set `pluginConfigs` for `agents-md@builtin`. The default is the mode this removal needs.
- Do not rewrite vendored `caveman-compress` or `compress` text. Those skills still describe an
  optional `CLAUDE.md` workflow upstream.
- Do not change Codex, Cursor, or Pi links. They already use `AGENTS.md`.
- Do not delete a project `CLAUDE.md` that is a regular file or that points somewhere other than
  `AGENTS.md`.
- Do not delete vendor copies, including the Caveman marketplace file and the Prettier extension
  file.

## Open Questions

None.

## Background

Installed Claude Code is `2.1.282`, which is past the v2.1.277 direct-read requirement and the
v2.1.281 Bedrock/telemetry caveat.

Default mode is `claude-md-or-agents-md`. A `CLAUDE.md`, `.claude/CLAUDE.md`, or `CLAUDE.local.md`
anywhere from the working directory upward leaves the project to the engine. The plugin then does
not load `AGENTS.md`. `~/.claude/CLAUDE.md`, the managed file, and `.claude/rules/` do not count.

`agent-config` links `~/CLAUDE.md` to `~/AGENTS.md`. That ancestor file counts, so native
`AGENTS.md` loading is off for every project under home, including ones whose own `CLAUDE.md` is
already gone. Project shims are the same kind of link. Official guidance for that shim is "nothing,
or delete the symlink": the content is read once either way. Deletion is the point of this plan,
because a remaining project symlink keeps the engine on `CLAUDE.md` and the plugin stays out.

The set of project shims changed while this plan was being written, so a named list would be stale
before implementation. Implementation walks `~/projects` at the time it runs.

Session start loads every `AGENTS.md` and `.claude/AGENTS.md` in the working directory and the
directories above it, once no counting `CLAUDE.md` remains. `~/AGENTS.md` is on that path for every
project under home. That is the global-rule load path after `~/CLAUDE.md` is removed.

`agents/claude/settings.json` has no `pluginConfigs` entry, so the built-in default applies. The
option is read from user settings, `--settings`, or managed settings, not from a project's
`.claude/settings.json`.

## Evidence

- Plugin contract, current `main` (commit `2fc72b2`, 2026-09-18):
  <https://github.com/anthropics/claude-code/blob/main/mods/agents-md/README.md>
- Operator docs, including the workaround table:
  <https://code.claude.com/docs/en/memory#agents-md>
- Live links on this host, 2026-09-25:
  - `~/AGENTS.md` -> `~/projects/agent-box-setup/agents/AGENTS.md`
  - `~/CLAUDE.md` -> `~/AGENTS.md`
  - `~/.claude/CLAUDE.md` was a regular file with one troubleshooting rule. On 2026-09-25 that rule
    was copied into `agents/AGENTS.md`. The user file is still present until implementation deletes
    it.
- A scan of `~/projects` on 2026-09-25 found only `CLAUDE.md` symlinks to `AGENTS.md`, including
  inside nested checkouts. Names are not recorded here. This repo has no root `CLAUDE.md`. A later
  scan is the removal set.
- Repo writers of the shim:
  - `modules/05-dev/agent-config/apply.sh` links `$HOME/CLAUDE.md`
  - `modules/05-dev/agent-config/verify.sh` requires that link
  - `agents/README.md` documents `ln -sfn ~/AGENTS.md ~/CLAUDE.md`
  - `agents/skills/new-project/SKILL.md` creates `ln -s AGENTS.md CLAUDE.md`
  - `agents/skills/sync-repo-setup/SKILL.md` requires the symlink

Known gaps while `AGENTS.md` is loaded through the plugin, from the plugin README. They apply only
after the shim is gone:

- Nested files attach on a text `Read` only.
- A nested file is not restored as recently read after compaction.
- `/cd` announces the new tree's files on the next request.
- Paths compare by spelling.
- `--add-dir` contributes no `AGENTS.md`.
- `/memory` and `#` do not know `AGENTS.md`.
- An external `@` import is kept only after the `CLAUDE.md` import approval, and that dialog is
  raised for `CLAUDE.md` alone.
- A non-fork subagent attaches a nested `AGENTS.md` again at its own first `Read`.

The public memory page lists a shorter set of the same gap: `InstructionsLoaded` hooks do not fire
for a directly loaded `AGENTS.md`, `--add-dir` still loads only `CLAUDE.md`, and an external
`@` import loads only if external imports were already approved.

## Decisions

- Remove every owned `CLAUDE.md` outside the project walk: `~/CLAUDE.md` and `~/.claude/CLAUDE.md`.
  Under `~/projects`, remove each `CLAUDE.md` that is a symlink to `AGENTS.md` or a symlink whose
  target is missing. Leave vendor copies outside that walk.
- Keep the troubleshooting rule. It is already in `agents/AGENTS.md`: when a diagnosis has more
  than one plausible cause or fix, stop, explain the options, and ask which one to try before
  editing; if a first fix already failed, pause and reassess before trying another. Confirm that
  section is still present, then delete `~/.claude/CLAUDE.md`.
- Keep the default `claude-md-or-agents-md` mode. Do not set `pluginConfigs`.
- Global rules stay in `~/AGENTS.md`. The memory docs load every `AGENTS.md` above the working
  directory, so that home file is the Claude global-rule path once `~/CLAUDE.md` is gone. A
  session that omits `~/AGENTS.md` fails verification. Do not recreate a `CLAUDE.md`.
- `apply.sh` removes `~/CLAUDE.md` only when it is a symlink to `~/AGENTS.md` (resolved path equal
  to the global rule file). A regular file or a different target is an error, same as today's
  refusal to replace a real file.
- `verify.sh` requires `~/CLAUDE.md` to be absent. `~/AGENTS.md` stays linked to
  `agents/AGENTS.md`.
- The project sweep is a fresh walk of every directory under `~/projects`, not a saved list. A
  regular `CLAUDE.md`, or a symlink that points somewhere other than `AGENTS.md` and still exists,
  stops that path and is reported. Do not delete it.

## Implementation

1. `modules/05-dev/agent-config/apply.sh`: drop the `~/CLAUDE.md` link. If that path is a symlink
   to `~/AGENTS.md`, remove it. If it exists and is anything else, exit with an error.
2. `modules/05-dev/agent-config/verify.sh`: drop the `~/CLAUDE.md` check. Fail when that path
   exists.
3. `agents/README.md`: remove the `~/CLAUDE.md` command. State that global rules are `~/AGENTS.md`,
   and that both `~/CLAUDE.md` and `~/.claude/CLAUDE.md` must be absent. Adjust the checklist line
   that says global instructions are linked for Claude Code.
4. `agents/skills/new-project/SKILL.md`: create repo-root `AGENTS.md` only. Do not add `CLAUDE.md`.
5. `agents/skills/sync-repo-setup/SKILL.md`: require repo-root `AGENTS.md`. If `CLAUDE.md` is a
   symlink to it, remove the symlink. If `CLAUDE.md` exists and is not that symlink, report it and
   do not delete it.
6. On the daily host, confirm the troubleshooting section is in `agents/AGENTS.md`, delete
   `~/.claude/CLAUDE.md`, and run apply. Then walk every directory under `~/projects`. Remove a
   `CLAUDE.md` when `readlink` is `AGENTS.md`, or when the symlink's target is missing. Leave a
   regular file or any other live target in place and report that path. Do not commit those other
   repos from this plan's repo.
7. Run the same apply on the agent VM when that guest is the target, then walk that machine's
   `~/projects` with the same rule.

## Acceptance Criteria

- `agent-config` apply and verify no longer create or require `~/CLAUDE.md`.
- `~/CLAUDE.md` is absent on each box the module is applied to. `~/AGENTS.md` still resolves to
  `agents/AGENTS.md`.
- `new-project` and `sync-repo-setup` no longer require a `CLAUDE.md` symlink.
- A fresh walk of `~/projects` finds no `CLAUDE.md` symlink to `AGENTS.md` and no `CLAUDE.md`
  symlink with a missing target. Each removed shim's directory still has `AGENTS.md` when the
  removed link pointed at one.
- `agents/AGENTS.md` still contains the troubleshooting rule, and `~/.claude/CLAUDE.md` is absent.
- `agents/claude/settings.json` still has no `instructionFiles` override.
- One Claude Code session in a project with only `AGENTS.md` reports
  `no CLAUDE.md found; AGENTS.md loaded:` and the loaded paths include both `~/AGENTS.md` and that
  project's `AGENTS.md`. A missing home path fails this check. Do not recreate a `CLAUDE.md`.

## Verification

```bash
cd ~/projects/agent-box-setup
./modules/05-dev/agent-config/verify.sh --target daily-host
test ! -e "$HOME/CLAUDE.md"
test -L "$HOME/AGENTS.md"
test ! -e "$HOME/.claude/CLAUDE.md"
grep -q 'stop and explain the options first' agents/AGENTS.md
find "$HOME/projects" -name CLAUDE.md -type l -exec sh -c '
  for path do
    if [ "$(readlink "$path")" = AGENTS.md ] || [ ! -e "$path" ]; then
      printf "still present: %s\n" "$path" >&2
      exit 1
    fi
  done
' sh {} +
# one claude session: startup line lists ~/AGENTS.md and the project AGENTS.md, and no CLAUDE.md
```

On the agent VM, the same verify with `--target agent-vm` after apply.
