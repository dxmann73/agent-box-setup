# Isolated personal browser network

Optional early host phase, after virtualization infrastructure and before a deployment's personal
browser guest. The deployment supplies a dedicated network name, bridge, address plan and nftables
rules. A NAT network alone does not enforce a browser's host/LAN isolation policy.

## Install the network guard

First inspect existing firewall rules and libvirt hooks. The commands below add a root-owned policy
and a separate hook; they must not replace another hook or flush other tables. The deployment's
rules must scope filtering to its browser bridge, allow DHCP/DNS, preserve replies to host-initiated
administration, and block browser-initiated host/private-network access. Check both host input and
routed traffic, IPv6 and source spoofing.

Set `BROWSER_NETWORK` and `BROWSER_RULES` from the deployment overlay. `BROWSER_RULES` is an
absolute path to its reviewed nft file; `BROWSER_NETWORK` contains only letters, digits, hyphens or
underscores.

```bash
[[ "$BROWSER_NETWORK" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]] || exit 1
[[ "$BROWSER_RULES" = /* && -r "$BROWSER_RULES" ]] || exit 1
sudo nft list ruleset
sudo nft --check -f "$BROWSER_RULES"
sudo install -d -m 0755 /etc/libvirt/network-guards /etc/libvirt/hooks/network.d
sudo install -m 0644 "$BROWSER_RULES" "/etc/libvirt/network-guards/$BROWSER_NETWORK.nft"
sudo install -m 0755 ~/projects/agent-box-setup/machines/host/network-guard-hook.sh \
  "/etc/libvirt/hooks/network.d/$BROWSER_NETWORK.guard"
sudo nft -f "/etc/libvirt/network-guards/$BROWSER_NETWORK.nft"
```

Restart the active network-managing daemon so it discovers the new hook before defining/starting the
browser network. On the monolithic setup in this repository:

```bash
sudo systemctl restart libvirtd
virsh -c qemu:///system list --all
```

On a deployment using modular libvirt daemons, restart `virtnetworkd` instead. Do not restart or
recreate guest domains. Follow the overlay's network and guest creation steps afterwards.

The hook applies the rules before network start and on guest attachment. Missing rules or nft errors
return nonzero and abort that operation. It never calls libvirt recursively. Files in `/etc/libvirt`
are root-owned copies: editing the checkout does not silently change active policy. Reinstall and
revalidate them after reviewing changes.

## Acceptance

An nft `accept` in one base chain does not bypass another firewall's drop. The dedicated policy adds
restrictions; existing UFW/libvirt rules must also permit required DNS, DHCP, outbound traffic and
return traffic. Inspect the complete live ruleset if an allowed operation fails.

Before browser logins, prove all of these from the new guest:

- DHCP lease, UDP/TCP DNS, public HTTPS, and outbound UDP needed by meetings work.
- Known listening host services fail through every host address, except the intended gateway DNS.
- Known listening private-LAN, agent-network and tailnet endpoints are unreachable.
- IPv6 cannot bypass the restrictions; spoofing a different source subnet does not bypass them.
- Host-initiated guest administration and its replies work.
- Unrelated host and agent-VM connectivity still works.
- Policy remains effective after the normal UFW and libvirt service reload/restart paths.

Probe known listening services with the correct protocol. A refused connection to a closed port or
an HTTP parser error against an SSH server is not proof of isolation. Compare rule counters before
and after each blocked probe. A failure in expected connectivity must stop acceptance.

Keep each policy in its own table and reload that table atomically. Do not use `flush ruleset` in
the deployment policy. An administrator operation that erases all nft tables also erases this guard;
restore and verify the guard before resuming browser use. Do not enable a competing firewall loader
that erases the rules on boot or restart.

References: [libvirt network hooks](https://libvirt.org/hooks.html#etc-libvirt-hooks-network),
[hook return codes](https://libvirt.org/hooks.html#return-codes-and-logging), and the
[nftables manual](https://netfilter.org/projects/nftables/manpage.html).
