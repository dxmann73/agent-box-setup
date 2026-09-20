# host-sudo-session

What: Daily-host sudo babysit module.

Does: Keeps a user-authenticated sudo session available during rootful setup work.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Run: `./keepalive.sh`

Verify current shell: `./verify.sh --require-active`

Verify BB babysit terminal: `./verify.sh --terminal-id TERM_ID`
