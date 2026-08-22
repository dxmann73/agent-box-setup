# 04 – Networking

Three separate paths, each with its own reason to exist (specification §11).

```text
                 ┌──────────────────────────────────────┐
   Internet ◄─────┤ NAT: LLM APIs, GitHub, packages, web │
                 └──────────────────────────────────────┘
                                  ▲
                                  │
   host model endpoint ◄──── host-only adapter ────► agent VM
                                  │
                                  ▼
                 ┌──────────────────────────────────────┐
        clients ─┤ T3 Code: host, LAN, remote via tailnet │
                 └──────────────────────────────────────┘
```

## 1. Outbound Internet (NAT)

The default NAT adapter from [`../host/05-hypervisor.md`](../host/05-hypervisor.md) covers cloud LLM
APIs, GitHub, package managers and browser testing. Nothing to configure beyond having it enabled.

Verify:

```bash
curl -sSI https://github.com | head -1
```

## 2. Host model endpoint

The local model runs on the host because it needs the GPU (specification §10). The VM reaches it
over a second, host-only adapter rather than over the LAN.

Host side: bind the inference server to the host-only interface address, not `0.0.0.0` and not just
`127.0.0.1`. See [`../local-llm/`](../local-llm/) for the server itself and
[`../host/03-system-config.md`](../host/03-system-config.md) for the firewall stance.

Find the address the host presents on that interface:

```bash
ip -4 addr show                       # on the host: the vmnet/host-only adapter
```

VM side, once the endpoint is up:

```bash
curl -sS http://HOST_ONLY_IP:PORT/v1/models
```

Record the resulting base URL in `~/.bash_secrets` so agents pick it up from one place.

- [ ] host-only adapter added to the VM
- [ ] inference server bound to it, not to the LAN
- [ ] base URL recorded in `~/.bash_secrets`

## 3. T3 Code reachability

The T3 Code server in the VM must be reachable from the host, from other machines on the network,
and from outside (specification §4, §11). Tailscale is the route for the last one.

The tailnet itself is not set up here. It is a piece of personal network infrastructure that spans
host, VM, laptop and phone, and it is documented in the `infra` project
(`docs/spec/tailscale.md`). Bring it up there first; this file only assumes the VM is a tailnet
node:

```bash
tailscale status
tailscale ip -4
```

Bind the server to that address, or publish it over Tailscale Serve HTTPS — see
[03-t3code.md](03-t3code.md) §3. Prefer either over opening a port on the router.

- [ ] VM appears in `tailscale status` on the host and on the phone
- [ ] T3 Code reachable from the host
- [ ] T3 Code reachable from a second machine on the LAN
- [ ] T3 Code reachable over the tailnet from outside the LAN
- [ ] no T3 Code port exposed directly to the public Internet

## 4. What must not happen

- no route from the VM into the host's personal services beyond the model endpoint
- no T3 Code port forwarded on the router
- no host `$HOME` exported over the network to the VM; use
  [06-shared-folders.md](06-shared-folders.md) for the few directories that need sharing

Next: [05-credentials.md](05-credentials.md)
