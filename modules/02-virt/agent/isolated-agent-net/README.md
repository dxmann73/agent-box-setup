# isolated-agent-net

What: Agent VM isolated network.

Does: Defines and guards the libvirt NAT network for the agent VM role. The guest gets Internet
egress, DHCP and DNS from the libvirt gateway, but guest-initiated access to host services on the
bridge and private/routed networks is blocked. Host services that the agent VM should use, such as
local model endpoints, live behind explicit Tailscale policy instead of the libvirt bridge.

Use `recipe.md` for the required values, then run `apply.sh` and `verify.sh` on the daily host that
owns the agent VM. The deployment overlay supplies the network name, bridge, address plan and DHCP
range.

Catalog metadata: see [Modular machine catalog](../../../README.md) for typ, sit, scp, requires, and
ticks.
