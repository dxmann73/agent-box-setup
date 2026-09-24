# ufw-firewall recipe

Run this module on `xhost`, `bhost`, and `xagt`. Not on `xchr`: the Chrome VM is isolated by the
host-side nft policy in `02-virt/chrome/isolated-browser-net` (see the catalog and
the Dave overlay's Chrome firewall policy); a guest UFW would only duplicate that
policy and add drift risk.

`kubuntu-baseline` must have run first. On daily hosts (`xhost`, `bhost`) `host-sudo-session`
provides the cached sudo the script needs.

Scope is the baseline only: default deny incoming, default allow outgoing, enable, survive reboot.
Per-service allow rules live in the modules that own the exposed service:

- Agent-VM SSH from the hypervisor bridge: `guest-ssh-sudo-bootstrap`.
- Host inference endpoint on `virbr0`: the `local-llm` repo.

Do not add those rules here. `libvirt` installs its own chains for guest NAT, so the `default`
network keeps working with UFW up.

## Lockout safety

Enabling UFW without allow rules drops in-flight incoming connections. Apply refuses to enable when
the current shell is over SSH and UFW is currently inactive, unless `--from-console` is passed:

- Preferred: run from a local console (login shell on the desktop, or `virsh console` for the
  agent VM) so the SSH path can be interrupted safely.
- Otherwise: add the allow rule for the SSH source first (via the owning module), verify a second
  fresh SSH session succeeds, then rerun this module with `--from-console` to acknowledge that
  the lockout risk has been handled.

Do not forward TCP/22 on the router.

## What apply does

- `sudo apt-get install -y ufw`.
- If UFW is currently inactive and the invoking shell is over SSH, refuse unless
  `--from-console` is passed.
- `sudo ufw default deny incoming`.
- `sudo ufw default allow outgoing`.
- `sudo ufw --force enable` (idempotent; a second run reports "already active").
- Preserves any existing user rules; adds none.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/00-os/ufw-firewall
./apply.sh
```

## Verify

```bash
./verify.sh
```
