# VM setup — handoff

**As of 2026-09-11.** Interactive walkthrough of the agent VM setup: each step is explained before
it runs, because the point is to learn what it does. Resume here in a fresh session, e.g.:

> Continue the VM setup walkthrough from `_incoming/vm-setup-handoff.md`. Interactive, explain each
> step before running it.

Delete this note when the VM setup is finished.

## Where we stand

### Phase 1 — create the VM: done and verified

Per [`../machines/host/05-hypervisor.md`](../machines/host/05-hypervisor.md) §5.

- domain and guest hostname `xmg-evo-agent-vm`; Kubuntu 26.04.1 desktop, user `dave`
- 20 vCPUs, 32 GiB RAM, 200 GiB sparse qcow2 in the `default` pool, SeaBIOS, `memfd` shared memory,
  SPICE `listen='none'` with virgl, autostart on
- DHCP address `192.168.122.123`; `getent hosts xmg-evo-agent-vm` resolves from the host
- domain XML saved to `~/vms/xmg-evo-agent-vm.xml`; ISO in `/var/lib/libvirt/boot/`
- console: `virt-viewer --attach xmg-evo-agent-vm`

### Phase 2 — guest bootstrap: started

Per [`../machines/vm/01-bootstrap.md`](../machines/vm/01-bootstrap.md).

- done: §1 `apt full-upgrade`, `openssh-server`, `ssh-copy-id` of the host's `~/.ssh/id_rsa.pub`;
  no reboot pending (`/var/run/reboot-required` absent)
- done: §2 passwordless sudo (was §5; the file now carries it directly after SSH, because everything
  later is driven from the host over SSH). `/etc/sudoers.d/agent-nopasswd`, mode `440`, single line
  `dave ALL=(ALL) NOPASSWD: ALL`, written with `visudo -f`
- done and verified: §3 autologin, written as `/etc/sddm.conf.d/99-autologin.conf` with `User=dave`,
  `Session=plasma`, `Relogin=false`. The `99-` prefix matters: Kubuntu's own `20-kubuntu.conf` sets
  an empty `[Autologin] User=` and `conf.d` is read in lexical order. After a reboot, `loginctl`
  shows session 1 on `seat0`/`tty1` with `Type=wayland`, `Active=yes`
- done: §4 `spice-vdagent` was already installed and `spice-vdagentd` is active (a `static` unit).
  The clipboard stays unavailable regardless, because the session is Wayland
- done and verified: §5 `qemu-guest-agent` installed and active; it survives a reboot without being
  enabled, and `virsh --connect qemu:///system domifaddr xmg-evo-agent-vm --source agent` answers
  from the host with `enp1s0 192.168.122.123/24`
- done: §3 screen blanking and autolock off, set in System Settings and read back. powerdevil 6.6
  uses `[AC][Display]` with `DimDisplayWhenIdle=false`, `DimDisplayIdleTimeoutSec=-1`,
  `TurnOffDisplayWhenIdle=false`, `TurnOffDisplayIdleTimeoutSec=-1` — there is no `DPMSControl`
  group any more, so the Plasma 5 keys would have written dead entries. Screen locking is
  `[Daemon] Autolock=false`, `LockOnResume=false`, `Timeout=0` in `kscreenlockerrc`
- open: §6 credentials, §7 `git curl` and Chrome, §8 first coding agent

### Host SSH agent: done and verified

Per [`../machines/host/03-system-config.md`](../machines/host/03-system-config.md) §4. Done:
`~/.ssh` at `700` and keys at `600`, `gcr-ssh-agent` masked, `SSH_AUTH_SOCK` set to
`/run/user/1000/openssh_agent` in the systemd user manager, `~/.ssh/config` with
`AddKeysToAgent yes`.

Verified after the reboot: `ssh -v xmg-evo-agent-vm true` reports
`Authenticated to xmg-evo-agent-vm ([192.168.122.123]:22) using "publickey"`, and `ssh-add -l`
lists `id_rsa`. The guest password was deleted from KWallet, so a future key failure shows up as a
password prompt instead of passing silently. `id_rsa` has a passphrase; it is in Bitwarden and in
KWallet.

### Guest automatic updates: done and verified

Per [`../machines/common/08-auto-updates.md`](../machines/common/08-auto-updates.md) §1 and §4.

- `unattended-upgrades` was already installed and both apt timers were already enabled; `needrestart`
  was not installed and is now
- `/etc/apt/apt.conf.d/52unattended-upgrades-local` written with the `Allowed-Origins` block,
  `Remove-Unused-Kernel-Packages`, `Remove-New-Unused-Dependencies`, `Automatic-Reboot "false"` and
  an empty `Mail`
- **no `Origins-Pattern` block yet**: the guest has only `o=Ubuntu` today. Add the third-party
  patterns in `vm/02`, when Chrome, `gh`, Docker and Node actually add their repos, and verify each
  `origin=` against `apt-cache policy | grep -o 'o=[^,]*' | sort -u`
- `/etc/needrestart/conf.d/50local.conf` written with `restart = 'a'` and `kernelhints = 0`
- `sudo unattended-upgrade --dry-run --debug` exits 0 with nothing to upgrade; the effective origins
  include `o=Ubuntu,a=resolute-updates` and `resolute-backports` is pinned to `-32768`
- §4 `Prompt=lts` was already set. §2 Flatpak skipped; §3 `update-tools.sh` still waits for the repo
  and the agents in the guest

## Next steps

1. **Rest of `vm/01`**: §3 screen blanking off — set it in System Settings once and copy the
   resulting `~/.config/powerdevilrc` keys into the doc, because powerdevil 6.6 exposes no
   `DPMSControl` key where the Plasma 5 layout had one. Then §6 credentials, §7 `git curl` and
   Chrome, §8 first coding agent and clone of this repo. §1, §2, §4 and §5 are done.
2. **Snapshot `clean-guest`** ([`../machines/vm/07-snapshots.md`](../machines/vm/07-snapshots.md)
   §2).
3. Then, in order: credentials (`vm/05` — pull it ahead of the toolchain, since `vm/02` already
   needs `gh auth`), toolchain (`vm/02`, and add the `Origins-Pattern` block there), networking
   (`vm/03`), BB (`vm/04`), shared folders (`vm/06`, only when needed), backup and rebuild test
   (`vm/07`), and the load test ([vm-load-test.md](vm-load-test.md)).

## Decisions already made

- disk 200 GiB; the Windows dual-boot partition gets shrunk later for more space
- 20 vCPUs, 32 GiB RAM, cgroup CPU weights left at 100
- installer ISO in `/var/lib/libvirt/boot/`, no ACL on `$HOME` for `libvirt-qemu`
- SeaBIOS by leaving `--boot` out; `--boot bios` is invalid syntax and `--boot firmware=bios` fails
  because Ubuntu ships no BIOS firmware descriptor
- VM name `<host>-agent-vm`, written as `xmg-evo-agent-vm` throughout the repo
- SSH before everything else in `vm/01`, so later steps can be pasted from the host
- keep `id_rsa` with its passphrase; one agent: OpenSSH + `ksshaskpass` + KWallet
- manual Kubuntu install this time; autoinstall on a future rebuild
- **guest session is Wayland**, not X11. Kubuntu 26.04 ships no Plasma X11 session:
  `plasma-workspace-x11` has no installation candidate, `/usr/share/xsessions/` does not exist, and
  only `plasma.desktop` is offered. `Session=plasmax11` was therefore dropped from `vm/01`. The cost
  is the SPICE clipboard, which `spice-vdagent` provides only under X11 — paste over SSH instead.
  Reconstructing an X11 session by hand from `kwin-x11` was rejected as unsupported on the machine
  that holds every agent credential
- `vm/01` §5 passwordless sudo moved to §2; `common/02` §5 cite and `verify-setup.sh`'s "section 3"
  cite updated to match

## Open items

- `vm/01` §3 suggests remote viewing with `virt-viewer --connect "qemu+ssh://…"`; with
  `listen='none'` and virgl that probably does not work. Untested; test when a second machine needs
  it.
- guest `sshd`: set `PasswordAuthentication no`, in the networking step before the VM joins the
  tailnet
- optional: a new `ed25519` host key; the autoinstall section expects `~/.ssh/id_ed25519.pub`
- `verify-setup.sh` now checks for the hostname `xmg-evo-agent-vm` literally
- `unattended-upgrade --dry-run` on the guest prints `Running on the development release` for
  26.04.1. With `DevRelease "auto"` it proceeds, so upgrades still apply; re-check after the next
  release-info update
- doc order to reconsider: `vm/01` §5 passwordless sudo had to be pulled in front of the auto-update
  step, because everything after SSH is driven from the host and `sudo` would otherwise prompt.
  Either move §5 up in `vm/01` or say so in `common/08`
- the doc changes from this walkthrough are committed through `2148e58`; this handoff note itself is
  untracked
