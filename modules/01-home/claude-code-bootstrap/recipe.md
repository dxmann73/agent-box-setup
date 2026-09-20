# claude-code-bootstrap recipe

Run this module on daily hosts (`xhost`, `bhost`) as the very first step on a fresh install. It gets
`claude` available so the setup agent can drive the remaining modules. Sign-in is `claude-login`.

Do not run this on `xchr` (Chrome VM has no repo clones and no agent CLIs). The agent VM (`xagt`)
gets the binary later, streamed from the host during guest baseline; it is not this module.

Kubuntu Desktop ships `curl` and `ca-certificates` by default; this module relies on them and
`verify.sh` asserts them. `git` is not needed here — it is installed by hand in
[`START-HERE.md`](../../../START-HERE.md) §2 alongside the two repo clones.

## First-run: repo is not yet cloned

Follow [`START-HERE.md`](../../../START-HERE.md). The command is the same as `apply.sh` below,
minus the idempotence check:

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Then run `claude` to complete browser sign-in (`claude-login`), and give the agent the START-HERE
task.

## Re-run after the repo is cloned

```bash
cd ~/projects/agent-box-setup/modules/01-home/claude-code-bootstrap
./apply.sh
```

`apply.sh` is idempotent: it runs the official installer only if `claude` is not on `PATH`, and does
not touch the sign-in state.

## What apply does

- Refuses to run as root; the installer writes under `$HOME`.
- Runs `curl -fsSL https://claude.ai/install.sh | bash` only if `command -v claude` returns nothing.
  The installer places `claude` under `~/.local/bin`.
- Never invokes `claude` itself. Sign-in is `claude-login`; running `claude` without a sign-in would
  prompt interactively and does not belong in an unattended apply step.

## Verify

```bash
./verify.sh
```

Checks: `ca-certificates` and `curl` present (fail-fast for minimal images); `claude` on `PATH`;
`claude --version` prints a version string. `--require-signed-in` is not offered here — that check
lives in `claude-login`.
