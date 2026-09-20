# clone-agent-box-setup

What: General setup repository checkout.

Does: Ensures `git` is installed and that `~/projects/agent-box-setup` is a working checkout on
machines that consume shared setup payloads. `claude-code-bootstrap` runs before this on daily
hosts; `git` is intentionally not part of that module. The first-ever clone is done by hand from
[`START-HERE.md`](../../../START-HERE.md); `apply.sh` never clones.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `./apply.sh`

Verify: `./verify.sh`

The first-ever clone on a daily host happens before this module exists on disk; the operator (or
Claude Code, driven by [`START-HERE.md`](../../../START-HERE.md)) types the equivalent commands
manually. `apply.sh` and `verify.sh` are for re-runs and for the agent VM, whose repo is placed by
the host-streamed guest baseline.
