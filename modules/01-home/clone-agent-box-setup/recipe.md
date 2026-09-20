# clone-agent-box-setup recipe

Run this module to guarantee that `~/projects/agent-box-setup` is a working checkout of
[`agent-box-setup`](https://github.com/dxmann73/agent-box-setup) and that `git` is installed. Daily
hosts run this right after `claude-code-bootstrap`; the agent VM has the repo placed by the
host-streamed guest baseline and re-runs this module for idempotence.

Do not run this on `xchr`: the Chrome VM has no repo clones and no agent CLIs.

## First-run: repo is not yet cloned

The first clone happens before `apply.sh` can exist on disk. Follow
[`START-HERE.md`](../../../START-HERE.md) §2 — the operator (or Claude Code) types those commands
by hand.

## Re-run after the repo is cloned

```bash
cd ~/projects/agent-box-setup/modules/01-home/clone-agent-box-setup
./apply.sh
```

`apply.sh` is idempotent: it installs `git` only if it is missing. It does not clone or fetch;
running from inside a checkout means the checkout is already in place.

## What apply does

- Refuses to run as root.
- Installs `git` via `apt-get` only if `command -v git` returns nothing. Needs `sudo` in that case.
- Never fetches, pulls, or overwrites the checkout.
- Never touches an overlay repo. `clone-dave-box-setup` owns `dave.box-setup`.

## Verify

```bash
./verify.sh
```

Checks: `git` on `PATH`; `~/projects/agent-box-setup/.git` exists; the `origin` remote points at
`https://github.com/dxmann73/agent-box-setup(.git)`; the checkout contains the payload trees this
repo advertises (`agents/`, `user-home/`, `modules/`).
