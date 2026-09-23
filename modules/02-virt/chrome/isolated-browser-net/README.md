# isolated-browser-net

What: Browser guest isolated network.

Does: Defines and guards the libvirt NAT network for a browser guest role. The guest gets Internet
egress, DHCP and DNS from the libvirt gateway, but guest-initiated access to host services,
private/routed networks, tailnets and other libvirt networks is blocked. Host-initiated guest
administration remains possible.

Use `recipe.md` for the required values, then run `apply.sh` and `verify.sh` on the daily host that
owns the browser VM. The deployment overlay supplies the network name, bridge, address plan and DHCP
range.

Catalog metadata: see [Modular machine catalog](../../../README.md) for typ, sit, scp, requires, and
ticks.
