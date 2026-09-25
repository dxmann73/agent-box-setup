---
name: bb-sudo-terminal
description:
  Open one visible BB side terminal for host sudo work; authenticate it, keep its sudo ticket alive,
  and run authorized privileged commands in that same terminal. While the password prompt is
  waiting, raise a yes/no question so the thread shows BB's question mark.
---

# BB sudo work terminal

Use when the user asks for a BB sudo terminal, sudo babysit, or rootful host work needs a side
terminal. The terminal is the sudo boundary: never request, read, echo, or send a password.

## Outcome

One named, interactive terminal remains open in the current thread. The user can see and use it. The
user enters their password there. While that prompt is waiting, a yes/no question is open in the
thread, so the sidebar shows the circled question mark instead of only the running circle. The agent
sends authorized rootful commands to that exact terminal, so its terminal-scoped sudo ticket
applies. Keep the ticket refreshed while work runs.

## Create one terminal

1. Read BB context with `bb status --json` and use its thread ID. Then discover terminals already
   attached to that thread:

   ```bash
   bb terminal list --thread THREAD_ID --json
   ```

   Inspect `sessions` with `status: "running"`. A terminal titled `sudo-work` is a sudo-work
   candidate.

1. Reuse an existing candidate; do not create a second terminal just because this skill was invoked
   in a later turn. Tell the user the reused terminal's title and ID, then verify its ticket as
   described below. If multiple candidates are running, inspect their recent output and ask the user
   to identify the authenticated one. Do not create another terminal in that case.
1. Create exactly one thread-scoped terminal only when no running sudo-work candidate exists. Do not
   create another unless the existing terminal has exited or the user says it is not visible.

   Launch `sudo-work.sh` from the same directory as this skill file. Resolve it to an absolute path
   and pass that path below. Do not retype the script.

   ```bash
   bb terminal create --thread THREAD_ID --title "sudo-work" \
     --command "bash SCRIPT_PATH" \
     --json
   ```

   `SCRIPT_PATH` is that absolute path. The script asks for the sudo password, plays a short bloop
   every 10 seconds until `sudo -v` returns, then refreshes the ticket, prints the ready banner, and
   opens the interactive shell. If `python3` or `paplay` is missing, it skips the sound and still
   runs `sudo -v`.

1. Read initial output with `bb terminal output TERM_ID --tail-bytes 4096`. Expect
   `[sudo: authenticate] Password:`.
1. Tell the user the exact title and ID, and ask them to enter their password there.
1. Raise a pending yes/no question so this thread shows BB's circled question mark. Call the
   `AskUserQuestion` tool. Do not wait for a freeform chat reply. The question stays up until they
   answer it, which is how they find this thread among other running ones.

   ```json
   {
     "questions": [
       {
         "question": "Have you entered the password in the sudo-work terminal TERM_ID?",
         "header": "Password",
         "multiSelect": false,
         "options": [
           {
             "label": "Yes",
             "description": "The password is entered in that terminal."
           },
           {
             "label": "No",
             "description": "The password is not entered yet."
           }
         ]
       }
     ]
   }
   ```

   Substitute the real terminal ID. Keep `header` to 12 characters or fewer. Two to four options are
   required.

   - Yes: check the terminal. The ready banner prints only after `sudo -v` succeeds, because
     `sudo-work.sh` runs under `set -e`:

     ```bash
     bb terminal wait TERM_ID --contains 'sudo work terminal ready' --from-start --timeout 30s
     ```

     The banner is printed by `sudo-work.sh`, not sent input, so it cannot false-match. If the
     banner is there, continue with the ticket check below.

   - No, a timeout, or Yes while the banner is still absent: call `AskUserQuestion` again with the
     same question. Do not start rootful work.

1. If `AskUserQuestion` is not available, enable the builtin plugin once:

   ```bash
   bb plugin enable ask-user-question
   ```

   It applies on the next provider session. This session cannot raise the question, so watch the
   terminal instead. Keep the `--timeout` below the agent tool's own command timeout, and tell the
   user the question mark needs a new session:

   ```bash
   bb terminal wait TERM_ID --contains 'sudo work terminal ready' --from-start --timeout 5m
   ```

1. When the banner appears, continue with the ticket check below. A Yes answer is not that check.
1. If the wait times out, run `bb terminal show TERM_ID --json`:
   - Terminal `running`, still at the password prompt: ask the user whether the terminal is visible.
     Terminal creation and output confirm server state only. They do **not** prove that the BB
     client showed a side terminal.
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
Wrap each command with a unique completion marker, then read or wait for that marker before the next
command. Example:

```bash
bb terminal send TERM_ID \
  --text "cd /absolute/repo/path && ./modules/BOX/apply.sh; status=\$?; marker_a=__BB_STEP_; marker_b=DONE__; printf '%s:%s\\n' \"\${marker_a}\${marker_b}\" \"\$status\"" \
  --enter
bb terminal wait TERM_ID --contains '__BB_STEP_DONE__:' --from-start --timeout 30m
```

Give every step its own marker name (`__BB_STEP1_`, `__BB_STEP2_`, ...). `--from-start` scans the
whole scrollback, so a reused marker matches an earlier step. After the marker matches, read the
result with `bb terminal output TERM_ID --tail-bytes N` and check the status before the next step.
Keep each `wait --timeout` below the agent tool's command timeout. For longer operations, repeat the
`wait` call rather than setting one long timeout.

Commands that need no root, for example `virsh -c qemu:///system` as a `libvirt` group member, may
run from the agent shell.

The terminal is interactive. The user may inspect output or stop work there. Keep it open until
rootful work and verification finish. Close it with `bb terminal close TERM_ID` only after telling
the user.

## Rules

- Never use `sudo -n` from the agent shell as evidence that this terminal is authenticated.
- Never run a long rootful command in a password-only `keepalive.sh` terminal. It cannot execute
  agent work in the same sudo tty.
- Do not treat a terminal prompt, asterisks, a chat message, or a Yes answer as successful
  authentication. Require the ready banner, then `__BB_SUDO_READY__`, from the terminal.
- While the password prompt is showing, call `AskUserQuestion` when that tool exists. The pending
  question is what shows the circled question mark. It does not replace the banner check.
- Assemble each completion marker at runtime. `bb terminal send` echoes its input, so a literal
  marker in the sent command produces a false `wait` match.
- The 45-second refresh loop in `sudo-work.sh` prevents an active long operation from expiring the
  sudo timestamp.
- Do not play the password reminder from the agent shell. `sudo-work.sh` owns that bloop, and it
  stops when `sudo -v` returns.
- Host sudo stays password-protected. Never add `NOPASSWD`.
