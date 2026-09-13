# 03 – Networking

Three separate paths, each with its own reason to exist (specification §11).

```text
                 ┌──────────────────────────────────────┐
   Internet ◄─────┤ NAT: LLM APIs, GitHub, packages, web │
                 └──────────────────────────────────────┘
                                  ▲
                                  │
   host model endpoint ◄──── libvirt virbr0 ──────► agent VM
        192.168.122.1             │
                                  ▼
                 ┌───────────────────────────────────────┐
        clients ─┤ BB: host and tailnet, no LAN NAT │
                 └───────────────────────────────────────┘
```

One virtio interface on the libvirt `default` network carries both paths. The bridge is NAT to the
Internet and, at the same time, the shortest route between guest and host — no second adapter is
needed for the model endpoint.

## 1. Outbound Internet (NAT)

The libvirt `default` network from [`../host/05-hypervisor.md`](../host/05-hypervisor.md) covers
cloud LLM APIs, GitHub, package managers and browser testing. Nothing to configure beyond having it
active and set to autostart (`virsh net-list --all` on the host).

Verify, in the guest:

```bash
curl -sSI https://github.com | head -1
```

## 2. Host model endpoint

The local model runs on the host because it needs the GPU (specification §10). The VM reaches it
across the libvirt bridge, not over the LAN and not over the tailnet.

Host side: bind the inference server to the bridge address — not `0.0.0.0`, and not only
`127.0.0.1`, which the guest cannot reach. See [local-llm](https://github.com/dxmann73/local-llm)
for the server itself and [`../host/03-system-config.md`](../host/03-system-config.md) for the
firewall stance.

```bash
ip -4 addr show virbr0                # the host's address on the libvirt default network
virsh net-dumpxml default | grep ip   # the same address, from libvirt's side
```

That address is `192.168.122.1` on a stock libvirt install. If ufw is enabled, open the port for
that interface only:

```bash
sudo ufw allow in on virbr0 to 192.168.122.1 port PORT proto tcp
```

VM side, once the endpoint is up:

```bash
curl -sS http://192.168.122.1:PORT/v1/models
```

Record the resulting base URL in `~/.bash_secrets` so agents pick it up from one place.

- [ ] inference server bound to `virbr0`, not to the LAN and not to loopback only
- [ ] ufw rule scoped to `virbr0` if the firewall is on
- [ ] guest reaches the endpoint, host's other services stay unreachable
- [ ] base URL recorded in `~/.bash_secrets`

## 3. BB reachability

The host AppImage server is the shared control plane and must be reachable from authorized remote
clients (specification §4, §11). The VM connects to it as an enrolled execution machine. Tailscale
carries both paths.

The tailnet itself is not set up here. It is personal network infrastructure (any service, not only
BB) and lives in `~/projects/infra/tailscale/` (inventory, join, SSH). Bring the VM node up there
first; this file only assumes the guest is a tailnet node:

```bash
tailscale status
tailscale ip -4
```

Keep every BB listener on loopback and publish the shared host server over Tailscale Serve HTTPS.
The VM's standalone fallback may also use Serve, or an SSH tunnel from the host; see
[04-bb.md](04-bb.md). The raw BB API is unauthenticated; do not bind it directly to the LAN or
tailnet.

The libvirt NAT network hides the guest from the LAN: other machines in the flat cannot reach
`192.168.122.x` at all, only the host can. That is deliberate. Every other client — laptop, phone —
reaches the VM as a tailnet node instead, which works identically at home and away, so no bridged or
macvtap interface is needed. Add one only if a device that cannot join the tailnet ever has to reach
the VM.

- [ ] VM appears in `tailscale status` on the host and on the phone
- [ ] VM enrolled and connected to the host BB server over the tailnet
- [ ] shared host BB origin reachable from authorized tailnet clients on and outside the LAN
- [ ] guest not reachable from other LAN machines except through the tailnet
- [ ] no BB port exposed directly to the public Internet

## 4. SSH reachability

The guest accepts standard OpenSSH through exactly two paths:

1. `tailscale0`, for administration clients separately authorized by tailnet policy and their
   source-bound public keys; and
2. the private libvirt interface, only from the physical host's single bridge address, for
   bootstrap, recovery, backup testing, and host automation.

It does not accept SSH from the LAN or public Internet. Do not bridge the guest NIC, forward port 22
on the router, enable Funnel, or allow the whole libvirt subnet. Tailnet policy and tests live in
[`infra/tailscale`](https://github.com/dxmann73/infra/tree/main/tailscale), not in this repository.

Resolve the guest interface, guest address, and hypervisor bridge address immediately before
changing UFW. With the current stock `default` network they are `enp1s0`, the guest's current
`192.168.122.x` address, and `192.168.122.1`, respectively; measurements override these examples.
Keep the working libvirt SSH session and graphical console open.

```bash
ip -brief address
ip -4 route
sudo ufw status verbose
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow in on tailscale0 to any port 22 proto tcp comment 'SSH over tailnet'
sudo ufw allow in on GUEST_LIBVIRT_INTERFACE from HYPERVISOR_BRIDGE_IPV4 \
  to any port 22 proto tcp comment 'SSH from hypervisor bridge'
sudo ufw enable
```

Before `ufw enable`, preserve any required existing rules and account for Docker or other software
that manages packet-filter chains. Afterward, verify IPv4 and IPv6 rules and open fresh sessions
through both allowed paths. From the host, the automation key must work when targeting the guest's
libvirt address and fail when targeting its Tailscale address. Password-only and
keyboard-interactive attempts must fail. Keep the recovery session open until every positive test
passes.

## 5. What must not happen

- no route from the VM into the host's personal services beyond the model endpoint
- no BB port forwarded on the router
- no host `$HOME` exported over the network to the VM; use
  [06-shared-folders.md](06-shared-folders.md) for the few directories that need sharing

Next: [04-bb.md](04-bb.md)
