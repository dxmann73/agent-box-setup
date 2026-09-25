# guest-ssh-sudo-bootstrap

What: Guest SSH/sudo bootstrap and exact host-bridge SSH allowance.

Does: Enables host-streamed guest setup with SSH, passwordless sudo, and an optional exact
host-bridge UFW allowance on guest machines.

Use this after a Kubuntu guest is installed and before any host-streamed package or integration
work. The recipe is role-neutral: it applies to the agent guest and the browser guest.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `./apply.sh`

Verify: `./verify.sh`
