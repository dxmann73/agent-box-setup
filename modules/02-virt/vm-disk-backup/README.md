# vm-disk-backup

What: Verifiable, same-host disk-copy backups for guest roles.

Does: Creates non-overwriting qcow2 recovery sets. `live` uses libvirt's push backup API for a
running guest; `offline` copies a shut-off guest's disk. Both modes save the inactive domain XML, a
manifest, and checksums.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `./apply.sh --domain DOMAIN --destination DIRECTORY --label LABEL --mode live|offline`

Verify: `./verify.sh --domain DOMAIN --backup-dir DIRECTORY --mode live|offline`
