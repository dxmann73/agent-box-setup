# isolated-agent-net recipe

This module creates one dedicated libvirt NAT network for an agent VM and installs the host nftables
guard that makes the bridge non-trusting.

The generic repo owns the policy shape. Deployment overlays own concrete values. Source the overlay
environment or export these values before running `apply.sh` or `verify.sh`:

```bash
export AGENT_NET_NAME=...
export AGENT_NET_BRIDGE=...
export AGENT_NET_ADDRESS=...
export AGENT_NET_NETMASK=...
export AGENT_NET_DHCP_START=...
export AGENT_NET_DHCP_END=...
```

Optional:

```bash
export AGENT_NET_NFT_TABLE=...
```

If `AGENT_NET_NFT_TABLE` is omitted, the scripts derive `agent_box_${AGENT_NET_NAME}` with dashes
changed to underscores.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/02-virt/agent/isolated-agent-net
./apply.sh
./verify.sh
```

`apply.sh`:

- refuses to run as root, in a guest, or without cached sudo;
- renders a libvirt network XML from the environment;
- refuses to redefine an existing network that does not exactly match the rendered XML;
- installs `/etc/libvirt/network-guards/$AGENT_NET_NAME.nft`;
- installs the libvirt network hook for this network;
- loads the nftables policy before the network starts;
- defines, starts and enables autostart for the libvirt network.

The nftables policy is scoped to `AGENT_NET_BRIDGE` and:

- permits DHCP and DNS to the libvirt gateway;
- blocks other guest-initiated traffic to host input on that bridge;
- blocks forwarded guest traffic to private, carrier-grade NAT, link-local, multicast and reserved
  IPv4 ranges;
- blocks IPv6 forwarding for this bridge;
- blocks spoofed source addresses outside the agent subnet;
- blocks unsolicited forwarded traffic into the guest bridge.

The policy is intentionally narrower than the browser-guest policy because the agent VM receives
its approved host-service path through Tailscale ACLs, not through extra bridge exceptions.

## Acceptance

After the guest exists, prove the policy from inside the agent VM:

- DHCP lease and DNS resolution work.
- Public HTTPS works.
- The libvirt gateway does not expose non-DNS host services to the guest.
- Known LAN, browser-network, default-libvirt-network and tailnet endpoints are unreachable unless
  Tailscale ACLs explicitly allow them through the guest's Tailscale interface.
- Host-initiated SSH/bootstrap access still works.

Inspect nftables counters while probing real listening services. A closed port alone is not proof of
isolation.

## Simplification candidate

`isolated-agent-net` and `isolated-browser-net` will be mostly the same machinery with different
policies. Once both module recipes exist, consider extracting a shared libvirt-network render/install
helper and keeping only per-role nftables policy templates in each module.
