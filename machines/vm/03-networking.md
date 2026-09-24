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
        clients ─┤ BB: authorized remotes, no LAN NAT    │
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
across the libvirt bridge, not over the LAN.

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

The host BB control plane must be reachable from authorized remote clients (specification §4, §11).
The VM connects to it as an enrolled execution machine.

Keep every BB listener on loopback. Remote clients may reach the host origin over Tailscale; this
box's URLs live in `~/projects/infra/tailscale/`. The VM connects back to the host origin through
its enrolled host-daemon service.

The libvirt NAT network hides the guest from the LAN: other machines in the flat cannot reach
`192.168.122.x` at all, only the host can. That is deliberate.

- [ ] VM enrolled and connected to the host BB server
- [ ] shared host BB origin reachable from authorized remotes (this box: infra)
- [ ] guest not reachable from other LAN machines except through intended remote access
- [ ] no BB port exposed directly to the public Internet

## 4. SSH reachability

The guest accepts standard OpenSSH from the private libvirt interface, only from the physical host's
single bridge address, for bootstrap, recovery, backup testing, and host automation.

It does not accept SSH from the LAN or public Internet. Do not bridge the guest NIC or forward port
22 on the router. Remote clients may use Tailscale; apply that path in
[`infra/tailscale`](https://github.com/dxmann73/infra/tree/main/tailscale).

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
sudo ufw allow in on GUEST_LIBVIRT_INTERFACE from HYPERVISOR_BRIDGE_IPV4 \
  to any port 22 proto tcp comment 'SSH from hypervisor bridge'
sudo ufw enable
```

Before `ufw enable`, preserve any required existing rules and account for Docker or other software
that manages packet-filter chains. Afterward, verify IPv4 and IPv6 rules and open a fresh session
through the hypervisor path. Password-only and keyboard-interactive attempts must fail. Keep the
recovery session open until every positive test passes.

## 5. What must not happen

- no route from the VM into the host's personal services beyond the model endpoint
- no BB port forwarded on the router
- no host `$HOME` exported over the network to the VM; use
  [06-shared-folders.md](06-shared-folders.md) for the few directories that need sharing

Next: [04-bb.md](04-bb.md)
