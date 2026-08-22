# 08 - Automatic updates

Both machines should stay close to the current patch state without being asked. This file sets that
up once per machine; after it, the only updates you type by hand are the two that must stay
deliberate (T3 Code, and release upgrades).

Run this early — right after the first `apt full-upgrade` on a new machine — so everything
installed afterwards is covered from the start.

## What updates itself, and what does not

| Thing | How it stays current | Deliberate? |
| --- | --- | --- |
| apt packages, kernel, security fixes | `unattended-upgrades`, daily | no |
| Chrome, `gh`, Docker, Node, VS Code | their own apt repos, same daily run | no |
| Snap packages | snapd refreshes itself, four times a day | no |
| Flatpak applications | user timer added below | no |
| Global npm CLIs, coding agents | weekly user timer added below | no |
| **T3 Code** (app + VM server) | **manual, both ends together** | **yes** |
| **Ubuntu release** (26.04 → next) | **manual `do-release-upgrade`** | **yes** |

T3 Code is excluded on purpose: client and server have to be on the same version
([`../vm/04-t3code.md`](../vm/04-t3code.md) §4), and an automatic bump on one side breaks the other.

## 1. apt: unattended upgrades

```bash
sudo apt install -y unattended-upgrades needrestart
```

Enable the daily timers:

```bash
sudo dpkg-reconfigure -plow unattended-upgrades
```

Answer yes. That writes `/etc/apt/apt.conf.d/20auto-upgrades`:

```text
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
```

By default only the `-security` pocket is installed. Widen it to regular updates and let it clean up
after itself — write `/etc/apt/apt.conf.d/52unattended-upgrades-local` so the change survives package
upgrades of `unattended-upgrades` itself:

```bash
sudo tee /etc/apt/apt.conf.d/52unattended-upgrades-local >/dev/null <<'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}:${distro_codename}-updates";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

// Third-party repos installed by this repo's guides.
Unattended-Upgrade::Origins-Pattern {
    "origin=Google LLC,codename=stable";
    "origin=packages.microsoft.com";
    "origin=Docker";
    "origin=Node Source";
    "origin=packagecloud.io/github/git-lfs";
};

Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Mail "";
EOF
```

`origin=` values are what the repositories actually publish, and they change. Verify against the real
list rather than trusting the block above:

```bash
apt-cache policy | grep -o 'o=[^,]*' | sort -u
```

Test the configuration without installing anything:

```bash
sudo unattended-upgrade --dry-run --debug
```

Check afterwards that it is running on its own:

```bash
systemctl status apt-daily.timer apt-daily-upgrade.timer
cat /var/log/unattended-upgrades/unattended-upgrades.log
```

### Reboots: false on both machines

`Automatic-Reboot "false"` above is deliberate on **both** the host and the VM, for different
reasons:

- **Host** — it is a laptop. An unattended reboot mid-work loses whatever was open.
- **VM** — it runs continuously with agents and dev servers attached
  ([`../vm/07-snapshots.md`](../vm/07-snapshots.md) §1). A reboot kills running agent threads.

So kernel and library updates are *installed* automatically but *activated* when you decide. Find
out when that is pending:

```bash
[ -f /var/run/reboot-required ] && cat /var/run/reboot-required.pkgs
```

`needrestart` covers the cheaper half of the problem: it restarts services that are running against
deleted libraries, so a plain library update does not need a reboot at all. Let it act without
asking during unattended runs:

```bash
sudo tee /etc/needrestart/conf.d/50local.conf >/dev/null <<'EOF'
# a = automatically restart services, i = interactive, l = list only
$nrconf{restart} = 'a';
# do not offer to reboot for kernel updates; that stays a decision
$nrconf{kernelhints} = 0;
EOF
```

In the VM, reboot after taking a snapshot rather than on a whim
([`../vm/07-snapshots.md`](../vm/07-snapshots.md) §2).

## 2. Snap and Flatpak

Snap refreshes itself; nothing to configure. Check or slow it down:

```bash
snap refresh --time
```

Flatpak has no built-in updater. A user timer covers it:

```bash
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/flatpak-update.service <<'EOF'
[Unit]
Description=Update Flatpak applications

[Service]
Type=oneshot
ExecStart=/usr/bin/flatpak update --assumeyes --noninteractive
EOF

cat > ~/.config/systemd/user/flatpak-update.timer <<'EOF'
[Unit]
Description=Weekly Flatpak update

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now flatpak-update.timer
```

Skip this entirely if you install no Flatpaks.

## 3. Global npm CLIs and coding agents

The agent CLIs and the global JS tools are outside apt. One script updates all of them, and a weekly
timer runs it. The script lives in
[`../../user-home/update-tools.sh`](../../user-home/update-tools.sh)
and is symlinked into `$HOME` alongside the other dotfiles
([00-home-environment.md](00-home-environment.md)):

```bash
ln -sf ~/projects/agent-box-setup/user-home/update-tools.sh ~/update-tools.sh
~/update-tools.sh
```

It updates the global npm packages, Claude Code, Cursor CLI, Codex and SDKMAN candidates, and prints
what changed. It deliberately does **not** touch T3 Code.

Run it weekly:

```bash
cat > ~/.config/systemd/user/update-tools.service <<EOF
[Unit]
Description=Update agent CLIs and global JS tools

[Service]
Type=oneshot
ExecStart=%h/update-tools.sh
EOF

cat > ~/.config/systemd/user/update-tools.timer <<'EOF'
[Unit]
Description=Weekly agent tooling update

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now update-tools.timer
loginctl enable-linger "$USER"     # run the timer without an active login session
```

Read the log after a run rather than assuming it worked:

```bash
journalctl --user -u update-tools.service -n 50
```

## 4. Release upgrades stay manual

An LTS-to-LTS upgrade changes the AMDGPU/Mesa stack, the libvirt version the VM depends on, and the
Node/Java versions under every project. It is not something to wake up to:

```bash
sudo sed -i 's/^Prompt=.*/Prompt=lts/' /etc/update-manager/release-upgrades
grep Prompt /etc/update-manager/release-upgrades
```

When you do run `do-release-upgrade`, snapshot the VM first
([`../vm/07-snapshots.md`](../vm/07-snapshots.md)) and re-run the hardware validation on the host
afterwards ([`../host/01-hardware-validation.md`](../host/01-hardware-validation.md)) — the GPU
stack is what moves.

## 5. Verification

```bash
systemctl is-enabled apt-daily.timer apt-daily-upgrade.timer
sudo unattended-upgrade --dry-run
systemctl --user is-enabled update-tools.timer
systemctl --user list-timers
```

## 6. Checklist

- [ ] `unattended-upgrades` and `needrestart` installed
- [ ] `20auto-upgrades` enables both periodic tasks
- [ ] `52unattended-upgrades-local` written, origins checked against `apt-cache policy`
- [ ] `--dry-run` completes without error
- [ ] `Automatic-Reboot` is `false`; pending reboots surface via `/var/run/reboot-required`
- [ ] `needrestart` set to restart services automatically
- [ ] Flatpak timer enabled, or no Flatpaks installed
- [ ] `~/update-tools.sh` symlinked, run once by hand, weekly timer enabled
- [ ] lingering enabled so user timers run without a login session
- [ ] release upgrades set to `Prompt=lts`
- [ ] T3 Code understood as manually updated on both ends together
