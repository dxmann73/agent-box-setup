# claude-code-bootstrap

What: Daily-host bootstrap agent.

Does: Installs `claude` (Claude Code CLI) early on `xhost` / `bhost` so an agent can drive the rest
of host setup. Sign-in is a separate module (`claude-login`); the binary is what this module owns.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `./apply.sh`

Verify: `./verify.sh`

The first-ever run happens before the repo is cloned; the operator types the equivalent commands
from [`START-HERE.md`](../../../START-HERE.md). `apply.sh` and `verify.sh` are for re-runs after
the START-HERE checkouts are in place.
