# Modular machine catalog

Plan: Manage the setup of different boxes in a uniform way so that we have

- one menu per box where we tick modules and
- per-host values (RAM, resolution, names) on the profile

Recorded 2026-09-14 from the two setup repos agent-box-setup and dave.box-setup.
Also pulled from current state in `xmg-evo` (this box), `xmg-evo-agent-vm`, and `chrome-vm`.

Coming hosts:

- blade-14 Kubuntu: same daily-host modules as xmg (`xhost` → `bhost`), except recorded `N`
  (no local agent VM, no BB server, no Java/k8s/Playwright on that laptop). Own KVM Chrome
  VM (~4 GiB), BB client of xmg, VS Code Remote SSH to xmg agent VM.
- blade-14 Windows / VMware Chrome. This stays in `dave.box-setup/windows-box/`.
- `local-llm` is a separate repo.
- Tailscale URLs / SSH `from=` stay in `infra`.

## Legend

xhost xmg-evo Kubuntu host
xagt xmg-evo-agent-vm
xchr chrome-vm guest role (today: xmg's guest). Blade's guest uses the same guest-side
ticks until a `bchr` column is needed.
bhost blade-14 Kubuntu

Y present - not present N decided no . TBD

typ role | tool | cfg | cred | app
sit - unattended | boot bootstrap | iso guest ISO | login login cluster | gcred guest creds
login on a guest is the gcred window.
scp gen agent-box-setup | dave overlay | infra | both gen and dave

Requires maps topological dependency. The catalog unit is a module (`node-24`, `kvm`, …).
Sit is the human window. Do not install-then-auth on every tool.

Daily-host exception: on `xhost` and `bhost` an agent does provisioning. Claude may be
signed in with Google on the fly in the stock browser so that agent can run. That is not
a template for Codex/Tailscale/BB/site logins.

Host sudo stays password-protected (no NOPASSWD). `host-sudo-session` is the babysit:
ask the user for a lingering authenticated sudo terminal so apt and other root steps do
not prompt every other command. Guest passwordless sudo stays `guest-ssh-sudo-bootstrap`.

## Target recipe folders

One directory per catalog module. Short README (what it is, what it does). Truth in
scripts / config beside it. Folders follow these sections, not host/vm/common.

```
modules/
  00-os/       desktop, kubuntu-baseline, ssh, ufw, sudo session, hardware-review
  01-home/     clones, dotfiles, timers, markdownlint
  02-virt/     kvm, ISO, nets, chrome-vm, agent-vm, guest-integration, snapshots
  03-tools/    jq, yq, rg, gh, wezterm, docker, …
  04-lang/     node, pnpm, java-stack, k8s-stack, imaging
  05-dev/      vscode, agent CLIs, BB, playwright, tailscale
  06-cred/     login modules (how to auth; secret values are not in this repo)
  07-apps/     dave personal (firefox, dropbox, vlc, …)
```

Keep `agents/` (skills/CLI payload), `user-home/` (symlinks), and `docs/specification/`
where they are. Tick-sets, host/VM values stay in this repo.

Overlay keeps
Windows, keys, and Dave-only values (identity, locale, URL lists). Sit is schedule
metadata, not a second folder tree.

## Current profile values (not ticks)

### chrome-vm (KVM module; Windows VMware guest is a different recipe)

value xmg now blade-14 Kubuntu

---

hostname chrome-vm TBD
vCPU 8 TBD
RAM 12288 MiB ~4 GiB
disk 40 GiB sparse TBD
resolution 2048x1152 measure Blade; do not copy xmg
network isolated 192.168.210.0/24 TBD (same role, own values)
autostart off (launcher) TBD
webcam host USB id TBD
Desktop share host Desktop -> guest ~/Desktop TBD
3D / audio SPICE GL; play+record TBD

### agent-vm (xmg only)

hostname xmg-evo-agent-vm
vCPU 20
RAM 32768 MiB
disk 80 GiB sparse
network isolated agent net + tailnet for host services (not virbr0 bind)

### Host RAM

xmg-evo 96 GB
blade-14 16 GB (~15 GiB usable)

### kubuntu-baseline values

dave login password ISO; not recorded here
locale en_US UI, de_DE formats (dave)
wallet one KWallet; guests passwordless; daily hosts protected
autologin guests Y; daily hosts N (host owns the lock screen)
host dirs ~/projects ~/vms ~/system-info ~/backup/vm (hosts only)

## Catalog

The grids are a menu, not a runbook. Section numbers are capability clusters.
Executor order is the operator schedule: ISO → START-HERE Claude (stock Firefox) →
setup agent applies ticked modules. START-HERE still apt-installs curl/git/ca-certificates
by hand so Claude can run; `kubuntu-baseline` later asserts they are present.

### 0. OS and host baseline

```
module                       typ   sit    scp    xhost xagt xchr bhost  requires
---------------------------  ----  -----  -----  ----- ---- ---- -----  ------------------------------------
kubuntu-desktop              role  iso    gen    Y     Y    Y    Y
kubuntu-baseline             cfg   -      both   Y     Y    Y    Y      kubuntu-desktop
host-sudo-session            cfg   boot   gen    Y     -    -    Y      kubuntu-desktop
hardware-review              cfg   -      both   Y     -    -    Y      kubuntu-desktop
git-identity                 cfg   -      dave   Y     Y    -    Y      kubuntu-baseline
ssh-client                   cfg   -      gen    Y     Y    -    Y      kubuntu-baseline
ssh-server                   tool  -      gen    Y     Y    Y    Y      kubuntu-baseline
ufw-firewall                 cfg   -      gen    Y     Y    -    Y      kubuntu-baseline
```

`kubuntu-desktop` is the installer (hostname, dave user, login password, disk).
`kubuntu-baseline` asserts git/curl/python3/ca-certs, unattended-upgrades, locale, one
wallet (guests passwordless, daily hosts protected), autologin on guests / off hosts.
`ssh-client` is the one-agent + ksshaskpass config, not the package.
`ssh-server` is sshd key-only on all four (guests: host-streamed setup; daily hosts: Tailscale/admin).
Chrome has no `ssh-client` and no guest UFW (isolation is host nft in §2). Agent-VM
guest→host allowlist is §2.

### 1. Repos and home

```
module                       typ   sit    scp    xhost xagt xchr bhost  requires
---------------------------  ----  -----  -----  ----- ---- ---- -----  ------------------------------------
claude-code-bootstrap        tool  boot   gen    Y     -    -    Y      kubuntu-desktop
clone-agent-box-setup        cfg   boot   gen    Y     Y    -    Y      kubuntu-desktop
clone-dave-box-setup         cfg   boot   dave   Y     -    -    Y      kubuntu-desktop
home-dotfiles                cfg   -      gen    Y     Y    -    Y      clone-agent-box-setup
update-tools-timer           cfg   -      gen    Y     Y    -    Y      home-dotfiles
markdownlint                 tool  -      gen    Y     Y    -    Y      clone-agent-box-setup node-24
```

Chrome VM must not clone these repos (current guest-setup rule).
`claude-code-bootstrap` is daily-host START-HERE only (`xhost` `bhost`). The agent VM
installs the binary as `claude-code` in §5 via host-streamed guest baseline. Re-auth
is `claude-login`. `git-identity` on `xagt` is streamed from the overlay; no
`clone-dave-box-setup` on the guest. `markdownlint` is its own module: symlink
`.markdownlint.json` into `~/projects/` and `npm i -g markdownlint-cli`. The skill
needs the CLI; this is not folded into `home-dotfiles`. Requires Node, so it runs
after `node-24` even though it sits in this cluster. `home-dotfiles` copies the
`.bash_secrets` template and symlinks it; tokens get filled later (login stage)
`update-tools-timer` stays its own module (weekly systemd user timer; the script
symlink is already `home-dotfiles`).

Section 1 closed.

### 2. Hypervisor and guests

```
module                       typ   sit    scp    xhost xagt xchr bhost  requires
---------------------------  ----  -----  -----  ----- ---- ---- -----  ------------------------------------
kvm                          role  -      gen    Y     -    -    Y      kubuntu-baseline
kubuntu-iso                  cfg   -      gen    Y     -    -    Y      kvm
isolated-agent-net           cfg   -      both   Y     -    -    N      kvm
isolated-browser-net         cfg   -      both   Y     -    -    Y      kvm
chrome-vm                    role  iso    both   Y     -    Y    Y      kvm isolated-browser-net kubuntu-iso
agent-vm                     role  iso    both   Y     Y    -    N      kvm isolated-agent-net kubuntu-iso
guest-ssh-sudo-bootstrap     cfg   iso    gen    -     Y    Y    -      guest exists
guest-integration            cfg   -      gen    -     Y    Y    -      guest-ssh-sudo-bootstrap
chrome-vm-packages           tool  -      dave   -     -    Y    -      chrome-vm guest-integration
host-url-launcher            cfg   -      dave   Y     -    -    Y      chrome-vm guest-integration
virtiofs-desktop-share       cfg   -      dave   Y     -    Y    Y      chrome-vm
virtiofs-user-data-shares    cfg   -      dave   Y     Y    -    N      agent-vm
vm-snapshots                 cfg   -      gen    Y     Y    Y    Y      guest exists
vm-disk-backup               cfg   -      both   Y     Y    Y    Y      vm-snapshots
```

xhost/bhost = Y on chrome-vm/agent-vm means that host owns the guest. xchr/xagt = Y means this box is that guest.

Two isolated libvirt nets. Chrome (`isolated-browser-net`): guest cannot hit host/LAN/tailnet.
Agent (`isolated-agent-net`): NAT + host nft — guest cannot reach host services on the
bridge except DHCP/DNS; bootstrap SSH is host-initiated. Host services (local-llm) bind
on the tailnet, not virbr0. ACLs in `infra`. `guest-integration` is qemu-guest-agent,
spice-vdagent, and the host clipboard bridge (always together on both guests).
`host-url-launcher` is the pinned Chrome-VM opener. `chrome-vm-packages` is Google
Chrome on `xchr` only, with unattended-upgrades for `origin=Google LLC`. Daily hosts
keep stock Firefox (`firefox-stock`); do not install Chrome there. Playwright
Chromium on `xagt` is not Chrome.
Shares: Desktop → Chrome guest; user-data → agent VM (overlay supplies the path).
`vm-snapshots` and `vm-disk-backup` stay separate (rollback vs disk copies; Chrome
3D guest is offline-only backup).

Section 2 closed.

### 3. Core tools

```
module                       typ   sit    scp    xhost xagt xchr bhost  requires
---------------------------  ----  -----  -----  ----- ---- ---- -----  ------------------------------------
build-essential              tool  -      gen    Y     Y    -    Y      kubuntu-desktop
jq                           tool  -      gen    Y     Y    -    Y      kubuntu-desktop
yq                           tool  -      gen    Y     Y    -    Y      kubuntu-desktop
ripgrep                      tool  -      gen    Y     Y    -    Y      kubuntu-desktop
fd-find                      tool  -      gen    Y     Y    -    Y      kubuntu-desktop
github-cli                   tool  -      gen    Y     Y    -    Y      kubuntu-desktop
wezterm                      tool  -      gen    Y     Y    -    Y      kubuntu-desktop
docker                       tool  -      gen    -     Y    -    -      kubuntu-desktop
```

Chrome gets none of these. `yq` matches `jq` (daily hosts + agent VM, not `xchr`).
Docker stays `xagt` only.

Section 3 closed.

### 4. Languages and JS CLIs

```
module                       typ   sit    scp    xhost xagt xchr bhost  requires
---------------------------  ----  -----  -----  ----- ---- ---- -----  ------------------------------------
node-24                      tool  -      gen    Y     Y    -    Y      kubuntu-desktop
pnpm                         tool  -      gen    Y     Y    -    Y      node-24
typescript                   tool  -      gen    Y     Y    -    Y      node-24
firecrawl-cli                tool  -      gen    Y     Y    -    Y      node-24
java-stack                   tool  -      dave   -     Y    -    N      kubuntu-desktop
imaging                      tool  -      dave   Y     -    -    Y      kubuntu-desktop node-24
k8s-stack                    tool  -      gen    -     Y    -    N      kubuntu-desktop
```

`typescript` includes `ts-node`. `java-stack` is SDKMAN + Java 21 + Maven + Quarkus
on `xagt` only. `imaging` is daily-host only: apt (ImageMagick, ffmpeg, Inkscape, …),
npm (sharp, resvg), and Python imaging (Pillow / python3-pil). `k8s-stack` is Helm +
kubectl + Minikube on `xagt` only. `node-24` includes the user npm prefix (`~/.npm-global`).

Section 4 closed.

### 5. Editor, agents, BB, browser automation

```
module                       typ   sit    scp    xhost xagt xchr bhost  requires
---------------------------  ----  -----  -----  ----- ---- ---- -----  ------------------------------------
vscode                       tool  -      gen    Y     -    -    Y      kubuntu-desktop
vscode-java-extensions       tool  -      dave   Y     -    -    Y      vscode
vscode-remote-ssh            cfg   -      gen    Y     -    -    Y      vscode ssh-client
cursor-agent-launcher        cfg   -      gen    Y     -    -    Y      cursor-cli imaging
claude-code                  tool  -      gen    Y     Y    -    Y      kubuntu-desktop
codex-cli                    tool  -      gen    Y     Y    -    Y      node-24
cursor-cli                   tool  -      gen    Y     Y    -    Y      kubuntu-desktop
pi                           tool  -      gen    Y     Y    -    Y      node-24
agent-config                 cfg   -      gen    Y     Y    -    Y      clone-agent-box-setup ticked CLIs
playwright-chromium          tool  -      gen    -     Y    -    N      node-24
bb-server                    role  -      gen    Y     -    -    N      libfuse
bb-enroll-execution-machine  cfg   login  gen    Y     Y    -    N      bb-server agent-vm
bb-client                    role  -      gen    -     -    -    Y      bb-server reachable
tailscale                    tool  -      infra  Y     Y    -    Y      kubuntu-desktop
```

Remote SSH: VS Code stays on the daily host (`xhost`, `bhost`). Remote clients install `~/.vscode-server` over SSH.
`agent-config` is global rules, skill links, and YOLO settings (links follow ticked CLIs).
`vscode` includes `user-home/vscode` settings/keybindings. Four agent CLIs stay
separate ticks (`claude-code`, `codex-cli`, `cursor-cli`, `pi`).

No standalone BB npm fallback on the agent VM. Shared control plane is the host AppImage (`bb-server`). The VM is only an enrolled execution machine (`bb-enroll-execution-machine`). Spec §4 fallback bullet dies with this module.
`bb-server` / `bb-client` install unattended; human BB UI is `bb-enroll-execution-machine`.
Remote BB is Tailscale Serve (`infra`), not BB Connect. `bb-connect` dropped.
`tailscale` install is unattended; account is `tailscale-login`. Playwright Chromium stays
`xagt` only.

Section 5 closed.

### 6. Credentials (cluster; do not sandwich with installs)

```
module                       typ   sit    scp    xhost xagt xchr bhost  requires
---------------------------  ----  -----  -----  ----- ---- ---- -----  ------------------------------------
setup-agent-login            cred  boot   gen    Y     -    -    Y      claude-code-bootstrap
github-auth                  cred  login  gen    Y     Y    -    Y      github-cli browser
claude-login                 cred  login  gen    Y     Y    -    Y      claude-code browser
codex-login                  cred  login  gen    Y     Y    -    Y      codex-cli browser
cursor-login                 cred  login  gen    Y     Y    -    Y      cursor-cli browser
pi-login                     cred  login  gen    Y     Y    -    Y      pi browser
firecrawl-login              cred  login  gen    Y     Y    -    Y      firecrawl-cli browser
vscode-settings-sync         cred  login  gen    Y     -    -    Y      vscode github-auth
tailscale-login              cred  login  infra  Y     Y    -    Y      tailscale browser
personal-browser-logins      cred  login  dave   -     -    Y    -      chrome-vm-packages
bitwarden-chrome             cred  login  dave   -     -    Y    -      personal-browser-logins
```

personal-browser-logins is one module. The URL list is a per-host value, not 30 ticks.
`FIRECRAWL_API_KEY` is written during `firecrawl-login` into the `.bash_secrets` file
that `home-dotfiles` already linked. No `bb-connect`: remotes use Tailscale Serve.

### 7. Personal host apps (dave)

```
module                       typ   sit    scp    xhost xagt xchr bhost  requires
---------------------------  ----  -----  -----  ----- ---- ---- -----  ------------------------------------
firefox-stock                app   -      dave   Y     -    -    Y      kubuntu-desktop
bitwarden-snap               app   login  dave   Y     -    -    Y      kubuntu-desktop
dropbox-client               app   login  dave   Y     -    -    Y      kubuntu-desktop
vlc                          app   -      dave   Y     -    -    Y      kubuntu-desktop
libreoffice                  app   -      dave   Y     -    -    Y      kubuntu-desktop
kdenlive                     app   -      dave   Y     -    -    Y      kubuntu-desktop
vibe-typer                   app   -      dave   Y     -    -    Y      kubuntu-desktop
claude-desktop               app   login  dave   Y     -    -    Y      kubuntu-desktop
chatgpt-desktop              app   login  dave   Y     -    -    Y      kubuntu-desktop
```

## Out of this catalog

```
local-llm / GPU runtime     https://github.com/dxmann73/local-llm
Tailscale URLs, SSH from=   infra
blade-14 Windows, VMware    dave.box-setup/windows-box/
Steam                       Windows only for now (that box)
AMD Ryzen AI notes          overlay extras/ (not a tick today)
bb-vm-runtime               dropped; do not install the agent-VM npm fallback server
```

## Live vs catalog (install later)

Catalog ticks above are the target. Live boxes still differ. After recipes exist, reconcile machines to this file.

```
module                       catalog                      live 2026-09-14
---------------------------  ---------------------------  --------------------------------
yq                           xhost xagt bhost             missing on sampled boxes
java-stack                   xagt only                    installed on host, not agent VM
k8s-stack                    xagt only                    not installed
bb-vm-runtime                absent                       npm fallback still on xagt
```

## Operator schedule

Unattended batches first. Not install then auth then next tool.

```
1  boot   setup agent on stock Firefox; clone repos; host-sudo-session on xhost/bhost
2  auto   kubuntu-baseline, kvm, ISO, isolated-browser-net, isolated-agent-net (sudo terminal)
3  iso    Chrome guest ISO / desktop; stream guest packages
4  auto   remaining unattended installs (tools, BB AppImage, CLIs)
5  login  Chrome URLs + Bitwarden, then gh/agents/Firecrawl/Tailscale/VS Sync
6  iso    agent VM ISO + baseline when ticked; gcred (incl. BB enroll) after clean-guest
6  iso    agent VM ISO + baseline when ticked; gcred only after clean-guest
```

blade-14 Kubuntu skips step 6, `bb-server`, and `agent-vm`.
It still needs `kvm` + `chrome-vm` at ~4 GiB, then `bb-client` + `vscode-remote-ssh` toward xmg.
