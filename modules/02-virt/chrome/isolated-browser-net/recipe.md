# isolated-browser-net recipe

This module creates one dedicated libvirt NAT network for a browser VM and installs the host
nftables guard that makes the bridge non-trusting.

The generic repo owns the policy shape. Deployment overlays own concrete values. Source the overlay
environment or export these values before running `apply.sh` or `verify.sh`:

```bash
export BROWSER_NET_NAME=...
export BROWSER_NET_BRIDGE=...
export BROWSER_NET_ADDRESS=...
export BROWSER_NET_NETMASK=...
export BROWSER_NET_DHCP_START=...
export BROWSER_NET_DHCP_END=...
```

Optional:

```bash
export BROWSER_NET_NFT_TABLE=...
```

If `BROWSER_NET_NFT_TABLE` is omitted, the scripts derive
`agent_box_${BROWSER_NET_NAME}` with dashes changed to underscores.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/02-virt/chrome/isolated-browser-net
./apply.sh
./verify.sh
```

`apply.sh`:

- refuses to run as root, in a guest, or without cached sudo;
- renders a libvirt network XML from the environment;
- refuses to redefine an existing network that does not exactly match the rendered XML;
- installs `/etc/libvirt/network-guards/$BROWSER_NET_NAME.nft`;
- installs the libvirt network hook for this network;
- loads the nftables policy before the network starts;
- defines, starts and enables autostart for the libvirt network.

The nftables policy is scoped to `BROWSER_NET_BRIDGE` and:

- permits DHCP and DNS to the libvirt gateway;
- blocks other guest-initiated traffic to host input on that bridge;
- permits host-initiated administration replies;
- blocks forwarded guest traffic to private, carrier-grade NAT, link-local, multicast, documentation,
  benchmark and reserved IPv4 ranges;
- blocks IPv6 forwarding and IPv6 host input from this bridge;
- blocks spoofed source addresses outside the browser subnet;
- blocks unsolicited forwarded traffic into the guest bridge.

## Acceptance

After the guest exists, prove the policy from inside the browser VM:

- DHCP lease and DNS resolution work.
- Public HTTPS works.
- Public UDP needed by meetings works.
- The libvirt gateway does not expose non-DNS host services to the guest.
- Known LAN, agent-network, default-libvirt-network and tailnet endpoints are unreachable.
- IPv6 cannot bypass the restrictions; spoofing a different source subnet does not bypass them.
- Host-initiated SSH/bootstrap access still works.
- The policy remains loaded after normal libvirt network restart paths.

Inspect nftables counters while probing real listening services. A closed port alone is not proof of
isolation.

## Simplification candidate

`isolated-agent-net` and `isolated-browser-net` now share most libvirt rendering and hook
installation code. Consider extracting a shared helper after the browser module has been exercised
on a real host; keep only the per-role nftables policy templates in each module.
