# 03 – T3 Code

Written from the upstream docs at ([`pingdotgg/t3code`](https://github.com/pingdotgg/t3code), `docs/user/`).
The install has not been run on this box yet; every checklist below is still open.
Correct this file from the real setup.

[T3 Code](https://t3.codes/) replaces herdr as the agent control plane (specification §4). It is a
client/server application: a server owns the projects, terminals, git state and provider sessions;
the desktop app, the mobile app and the hosted web app are only clients that attach to it.

Prerequisite: Tailscale is up on the host and on the VM before this file. That setup is documented
in the `infra` project, `docs/spec/tailscale.md`, not here.

## Target shape

Two servers, one client. The host desktop app is the single UI for both environments.

```text
host                                            agent VM
├── T3 Code desktop app  ─── environments ──┬── T3 Code server (headless, systemd user service)
│     the only GUI                          │     ├── many concurrent coding agents
├── T3 Code server (local environment)      │     └── terminals: dev servers, watchers, builds
│     └── host-scoped work only             │
└── local model runtime (GPU)               └── projects agents work on

                phone / laptop ──► same VM server over the tailnet
```

Why two servers rather than one: the VM is the security boundary (§2, §3), so everything an agent
touches runs there. The host still needs its own environment for work that cannot be done in the VM
— the GPU model runtime, the hypervisor, personal repos. A T3 Code server drives provider CLIs on
its own machine; it cannot run an agent "on the host" from the VM server. One app, two servers.

### Does one app really hold both?

Yes. Environments are a first-class concept in T3 Code:

- **Settings → Connections** lists *This environment* (the app's own local backend) plus every saved
  remote environment.
- Adding a project (Command Palette → **Add Project**) asks which environment it lives on. Every
  saved environment is offered, not only the local one.
- The **Usage** page aggregates Codex and Claude activity across all connected environments.

So a single host app can hold host projects and VM projects side by side. What it does *not* do is
mix them inside one thread: a thread belongs to one environment, and its agent, terminal and files
are that environment's.

## 1. Prerequisites in the VM

- Node.js `^22.16 || ^23.11 || >=24.10` — see
  [`../common/03-dev-environment.md`](../common/03-dev-environment.md)
- at least one provider CLI installed *and authenticated in the VM*, from
  [`../common/01-agent-setup.md`](../common/01-agent-setup.md)

T3 Code drives provider CLIs, it does not ship them. Log in on the machine that runs the server, not
on the machine you browse from:

| Provider | Binary | Login |
| --- | --- | --- |
| Codex | `codex` | `codex login` |
| Claude | `claude` | `claude auth login` |
| Cursor | `cursor-agent` | `agent login` (!) |
| Grok Build | `grok` | `grok login` |
| OpenCode | `opencode` | `opencode auth login` |

Codex and Claude are enabled by default; the rest are switched on per provider card in
**Settings**.

Each CLI must be on the server's `PATH` or have an explicit **Binary path** set in Settings — nvm
installs are the usual reason a CLI is invisible to a service-started server.

## 2. Headless server in the VM

The VM has no reason to run the Electron app. Run the server only.

```bash
npx t3@latest serve --host "$(tailscale ip -4)"
```

`t3 serve` starts the server without opening a browser and prints a connection string, a one-time
pairing token, a pairing URL and a QR code. Default port is `3773`. `npx t3@latest --help` has the
full flag reference.

Bind deliberately: the tailnet address, or the host-only adapter address from
[04-networking.md](04-networking.md). Not `0.0.0.0`, and not `127.0.0.1` if a client outside the VM
has to reach it.

### Make it outlive the terminal

`t3 serve` in an SSH session dies with the session. Install the background service instead —
a systemd user unit at `~/.config/systemd/user/t3code.service`, with lingering enabled, so it
starts at VM boot and survives logout:

```bash
npx t3@latest service install
npx t3@latest service status
```

`service update` updates or repairs it, `service uninstall` removes it from startup. The service
runs a small stable launcher and installs exact versions separately, so a failed update rolls back
to the previous version — including the database snapshot.

This is what satisfies §14: sessions and agent processes survive the host-side client
disconnecting, because the client never owned them.

## 3. Pairing a client

From the VM, mint a token for an already-running server:

```bash
npx t3 pair                # prints pairing URL + QR
npx t3 pair --tailscale    # publishes over Tailscale Serve HTTPS and pairs through the MagicDNS URL
```

Pairing is one-time: the device exchanges the token for an authenticated session, and does not need
the token again. Mint a new one per device.

Routes to the VM server, in the order to prefer them:

1. **Tailscale MagicDNS over HTTPS** — `t3 serve --tailscale-serve` (or `t3 pair --tailscale`)
   configures Tailscale Serve on 443 and advertises `https://machine.tailnet.ts.net/`. Required for
   the hosted web app at `https://app.t3.codes`, which cannot talk to a plain `http://` backend
   because of mixed-content rules. `tailscale serve --https=443 off` undoes the mapping.
2. **Tailnet IP** — `http://100.x.y.z:3773`, fine for the desktop app.
3. **Host-only adapter** — host → VM without touching the LAN.
4. **SSH launch** — desktop app, **Settings → Connections → Add environment**, SSH target
   `user@vm-host`. The app starts or reuses a remote server and port-forwards the remote loopback
   port. Needs a compatible `node` in a *non-interactive* shell.

Not wanted: a router port forward. Nothing about this server belongs on the public Internet
([04-networking.md](04-networking.md)).

## 4. Version skew

Client and server should be on the same version; T3 Code warns in the conversation and in
**Settings → Connections** when they differ. Because the VM runs the background service, the fix is
usually the **Update server** button in the app. The manual equivalent on the VM, with the exact
version from the warning:

```bash
npx t3@<client-version> service update
```

Updating restarts the server — let running agents and terminal commands finish first. The project is
pre-1.0 and ships nightlies daily, so treat skew as routine, not as an incident.

## 5. Permission modes

Threads default to **Full access** — commands and edits without prompts. That matches YOLO mode
inside the VM, which is the whole reason the VM exists.

On the **host** environment the calculus is different: there is no VM boundary there. 
We are slower there and want to use
**Supervised** or **Auto-accept edits** for host projects, and keep **Full access** for VM threads.
Modes are per thread; a thread created from another thread inherits its mode.

## 6. Configuration in this repo

T3 Code keeps its install and data under `~/.t3`. Per §9 this repo is the source of truth for agent
configuration, so a rebuilt VM must get the same setup back from
[`../configs/`](../configs/).

To capture once the setup is real:

- [ ] which files under `~/.t3` are configuration and which are state/database
- [ ] provider instance settings (binary paths, enabled providers, multi-account setup)
- [ ] the serve/service invocation, including the bind address
- [ ] a script that reinstalls the service and restores that configuration on a fresh VM

## 7. Verification

- [ ] `npx t3@latest service status` shows the service installed and running in the VM
- [ ] server survives `logout` and a VM reboot
- [ ] host desktop app lists both environments in **Settings → Connections**
- [ ] a project on the host and a project in the VM are both open in the same app window
- [ ] agent thread runs in the VM environment and edits only VM files
- [ ] a terminal (dev server) started in the VM environment keeps running after closing the app
- [ ] two concurrent agents in the VM, client disconnected and reattached, both sessions intact
- [ ] phone or laptop pairs over the tailnet from outside the LAN
- [ ] no T3 Code port forwarded on the router

Next: [04-networking.md](04-networking.md)
