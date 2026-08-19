# 03 – Herdr

> **Status: not yet written.** The specification fixes what herdr must do (§4); the install and
> configuration steps still have to be captured from an actual setup. Do not treat this file as
> verified.

Herdr is the primary UI for observing and interacting with agents. One server runs inside the VM;
everything else connects to it.

## Target shape

```text
agent VM
└── herdr server (single instance)
    ├── many concurrent coding agents
    └── ordinary terminals: dev servers, test watchers, builds
          ▲                    ▲
          │                    │
     host client         laptop / other machines
```

## Requirements it has to satisfy

- one server per VM, many agents under it (§4)
- ordinary long-running processes as well as agents — dev servers, test watchers, builds (§4)
- reachable from the host (§4)
- reachable from other machines over the network (§4, §11)
- reachable from the public Internet by some route: Tailscale, or the herdr app (§11)
- sessions and agent processes survive the host-side client disconnecting (§14)
- find and leverage [plugins](https://herdr.dev/plugins/)

## To capture

- [ ] install method and version pinning
- [ ] service definition so it starts with the VM and outlives any client
- [ ] listen address and port, and how that interacts with the interfaces in
      [04-networking.md](04-networking.md)
- [ ] authentication for remote clients
- [ ] where its configuration lives in [`../configs/`](../configs/), so a rebuilt VM gets the same
      setup from this repo (§9)
- [ ] client setup on the host and on other machines
- [ ] verification: start server, attach two agents, disconnect the client, reattach, confirm both
      sessions survived

Next: [04-networking.md](04-networking.md)
