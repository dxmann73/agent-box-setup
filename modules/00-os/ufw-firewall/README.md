# ufw-firewall

What: Default-deny UFW baseline.

Does: Installs `ufw`, sets default deny incoming / allow outgoing, and enables it. Adds no
per-service allow rules; those live in the modules that own the exposed service.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `./apply.sh`

Verify: `./verify.sh`
