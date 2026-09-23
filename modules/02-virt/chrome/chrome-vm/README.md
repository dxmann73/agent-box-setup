# chrome-vm

What: Personal browser guest role.

Does: Tracks the Kubuntu guest used for isolated browser activity.

ISO note: installs from the verified `kubuntu-iso` artifact in `/var/lib/libvirt/boot/`; this module
must not download or verify installation media itself.

Catalog metadata: see [Modular machine catalog](../../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `./apply.sh`

Verify: `./verify.sh`
