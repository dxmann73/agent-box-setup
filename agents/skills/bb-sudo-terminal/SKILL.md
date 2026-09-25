---
name: bb-sudo-terminal
description: Open one visible BB side terminal for host sudo work; authenticate it, keep its sudo ticket alive, and run authorized privileged commands in that same terminal.
---

# BB sudo work terminal

Use when the user asks for a BB sudo terminal, sudo babysit, or rootful host work needs a side
terminal. The terminal is the sudo boundary: never request, read, echo, or send a password.

## Outcome

One named, interactive terminal remains open in the current thread. The user can see and use it.
The user enters their password there. The agent sends authorized rootful commands to that exact
terminal, so its terminal-scoped sudo ticket applies. Keep the ticket refreshed while work runs.

## Create one terminal

1. Read BB context with `bb status --json` and use its thread ID. Then discover terminals already
   attached to that thread:

   ```bash
   bb terminal list --thread THREAD_ID --json
   ```

   Inspect `sessions` with `status: "running"`. A terminal titled `sudo-work` is a
   sudo-work candidate.

1. Reuse an existing candidate; do not create a second terminal just because this skill was
   invoked in a later turn. Tell the user the reused terminal's title and ID, then verify its
   ticket as described below. If multiple candidates are running, inspect their recent output and
   ask the user to identify the authenticated one. Do not create another terminal in that case.
1. Create exactly one thread-scoped terminal only when no running sudo-work candidate exists.
   Do not create another unless the existing terminal has exited or the user says it is not
   visible.

   ```bash
   bb terminal create --thread THREAD_ID --title "sudo-work" \
     --command "bash -lc 'set -Eeuo pipefail; sudo -v; (while sleep 45; do sudo -n -v || exit; done) & refresh_pid=\$!; trap \"kill \$refresh_pid 2>/dev/null || true\" EXIT INT TERM; printf \"\\nBB sudo work terminal ready. Agent runs approved sudo commands here.\\n\\n\"; bash --noprofile --norc -i'" \
     --json
   ```

1. Read initial output with `bb terminal output TERM_ID --tail-bytes 4096`. Expect
   `[sudo: authenticate] Password:`.
1. Tell the user the exact title and ID, and ask them to enter their password there. Do not end
   the turn to wait for a chat reply. Watch the terminal instead. The ready banner prints only
   after `sudo -v` succeeds, because the command runs under `set -e`:

   ```bash
   bb terminal wait TERM_ID --contains 'sudo work terminal ready' --from-start --timeout 5m
   ```

   The banner is part of the create command, not sent input, so it cannot false-match. Keep the
   `--timeout` below the agent tool's own command timeout.

1. When the banner appears, continue with the ticket check below. No user confirmation needed.
1. If the wait times out, run `bb terminal show TERM_ID --json`:
   - Terminal `running`, still at the password prompt: ask the user whether the terminal is
     visible. Terminal creation and output confirm server state only. They do **not** prove that
     the BB client showed a side terminal.
   - Terminal exited (for example, after three wrong passwords): report the exit and ask before
     creating a new terminal.
1. If the terminal is not visible, stop. Report its ID and `bb terminal show TERM_ID --json` state.
   Do not silently create extra terminals. The user must resolve the BB UI issue or direct a
   different terminal workflow.

## Verify and use it

After the ready banner appears, or when reusing a terminal, verify the ticket in that terminal:

```bash
bb terminal send TERM_ID \
  --text "sudo -n true && marker_a=__BB_SUDO_; marker_b=READY__; printf '%s\\n' \"\${marker_a}\${marker_b}\"" \
  --enter
bb terminal wait TERM_ID --contains '__BB_SUDO_READY__' --from-start --timeout 30s
```

For every rootful recipe, send the command through `TERM_ID`; do not run it from the agent shell.
Wrap each command with a unique completion marker, then read or wait for that marker before the
next command. Example:

```bash
bb terminal send TERM_ID \
  --text "cd /absolute/repo/path && ./modules/BOX/apply.sh; status=\$?; marker_a=__BB_STEP_; marker_b=DONE__; printf '%s:%s\\n' \"\${marker_a}\${marker_b}\" \"\$status\"" \
  --enter
bb terminal wait TERM_ID --contains '__BB_STEP_DONE__:' --from-start --timeout 30m
```

Give every step its own marker name (`__BB_STEP1_`, `__BB_STEP2_`, ...). `--from-start` scans the
whole scrollback, so a reused marker matches an earlier step. After the marker matches, read the
result with `bb terminal output TERM_ID --tail-bytes N` and check the status before the next step.
Keep each `wait --timeout` below the agent tool's command timeout. For longer operations, repeat
the `wait` call rather than setting one long timeout.

Commands that need no root, for example `virsh -c qemu:///system` as a `libvirt` group member, may
run from the agent shell.

The terminal is interactive. The user may inspect output or stop work there. Keep it open until
rootful work and verification finish. Close it with `bb terminal close TERM_ID` only after telling
the user.

## Rules

- Never use `sudo -n` from the agent shell as evidence that this terminal is authenticated.
- Never run a long rootful command in a password-only `keepalive.sh` terminal. It cannot execute
  agent work in the same sudo tty.
- Do not treat a terminal prompt, asterisks, or a user chat message as successful authentication;
  require the ready banner, then `__BB_SUDO_READY__`, from the terminal.
- Do not ask the user to confirm the password in chat. Watch the terminal output.
- Assemble each completion marker at runtime. `bb terminal send` echoes its input, so a literal
  marker in the sent command produces a false `wait` match.
- The 45-second refresh loop prevents an active long operation from expiring the sudo timestamp.
- Host sudo stays password-protected. Never add `NOPASSWD`.
