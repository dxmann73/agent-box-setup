# kvm

What: Host KVM/libvirt capability for daily hosts.

Does: Installs the hypervisor packages, the stock `default` network and storage pool, guest-name
resolution, and the host shutdown policy that suspends running guests.

Scope note: this is the base libvirt substrate only. ISO media, isolated guest networks, guest
domains, shares, snapshots, backup, and service firewall rules stay in their own later modules.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `./apply.sh`

Verify: `./verify.sh`
