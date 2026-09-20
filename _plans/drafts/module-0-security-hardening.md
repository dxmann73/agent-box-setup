# Module 0 security hardening

- created: 2026-09-20
- priority: p2 (medium) — real hardening gaps and lockout footguns, no live incident
- source: security review of modules/00-os on 2026-09-20
- branch: main

Security review of module 0 (`modules/00-os`). Findings and proposed fixes below.
Verbatim from the review.

## Higher-impact gaps

**1. sshd `Match` / secondary drop-in overrides not caught (`modules/00-os/ssh-server/apply.sh:132`)**
`sshd -T` without `-C user=...,addr=...` returns only the default context. Recipe warns about `Match` blocks (`recipe.md:50`) but the effective-value check would still pass while `Match Address 192.168.0.0/16` re-enables `PasswordAuthentication yes`. Cloud-init check on line 66-73 covers only three keywords, not `AllowUsers`/`AllowGroups`/`Match`/`Include`. Consider testing `sshd -T -C user=$USER,host=$HOST,addr=0.0.0.0` and grepping the full config tree for `Match|Include`.

**2. sshd drop-in is thin on defense-in-depth (`modules/00-os/ssh-server/apply.sh:89-97`)**
Absent from the six keywords: `AllowUsers`/`AllowGroups`, `X11Forwarding no`, `AllowTcpForwarding no`, `AllowAgentForwarding no`, `PermitTunnel no`, `GatewayPorts no`, `HostbasedAuthentication no`, `GSSAPIAuthentication no`, `UsePAM no`, `PubkeyAcceptedAlgorithms`/`Ciphers`/`KexAlgorithms`/`MACs` allowlists, `LoginGraceTime`, `MaxAuthTries`, `MaxSessions`. Ubuntu 24.04 defaults are mostly sane, but any local account with an authorized_keys gets shell + tunnels + agent forwarding. Trust map assumes `from=` per-key; without `AllowGroups ssh-users` a stray new account bypasses the map.

**3. Guest sudoers is unconditional NOPASSWD ALL (`modules/00-os/kubuntu-baseline/apply.sh:103-115`)**
`$setup_user ALL=(ALL) NOPASSWD: ALL` means any process running as the guest user reaches root with no prompt. Attack surface = every unattended package install, npm/pnpm postinstall, VS Code extension, agent tool inside the guest. Guest sandbox theory OK; still, narrowing to specific commands (or gating via PAM policy) would blunt lateral moves within the guest.

**4. Locale env vars flow unvalidated into sed (`modules/00-os/kubuntu-baseline/apply.sh:175-183`)**
`KUBUNTU_BASELINE_LOCALES` splits on IFS and interpolates unchecked into `sed -i "s/^# *${locale_name}[[:space:]]\\+UTF-8/..."`. Value containing `/` or sed metachars breaks the replacement, and unquoted `$locale_list` in `for` + `locale-gen $locale_list` allows glob expansion. Requires root already, so not remote-exploitable — but a bad env var trashes `/etc/locale.gen`. Whitelist `^[a-zA-Z_]+\.UTF-8$` before use.

**5. Daily-host screen never auto-locks (`modules/00-os/kubuntu-baseline/apply.sh:125-127`, `verify.sh:138`)**
`Autolock false`, `Timeout 0`. Physical-access exposure while unattended. Verify confirms it's disabled — that is the intent, but ssh-agent (systemd-user, linger enabled) holds decrypted keys across desktop lock events that never fire. Combine with `AddKeysToAgent yes` + persistent linger → any process running as the user (e.g. a compromised extension) can sign with the private key silently. Consider at least `LockOnResume true` triggers (already set) plus keyring re-lock hook, or `AddKeysToAgent confirm` for the sensitive keys.

**6. `--i-have-a-key` reloads sshd on operator claim only (`modules/00-os/ssh-server/apply.sh:151-160`)**
No independent check that some other account has authorized_keys. Wrong operator claim → passwordless-disabled sshd with zero keys anywhere → console-only recovery. Cheap fix: iterate `/home/*/.ssh/authorized_keys` and `/root/.ssh/authorized_keys` and require at least one non-empty file, even under the override.

## Medium

**7. Kernel security patches never auto-apply (`modules/00-os/kubuntu-baseline/apply.sh:201`)**
`Unattended-Upgrade::Automatic-Reboot "false"` + `needrestart` `kernelhints = 0`. Services restart, kernel does not. On a long-running host this leaves known-CVE kernels live indefinitely. Add a reminder mechanism or `Automatic-Reboot-WithUsers "true"` + a fixed hour, or at least a verify check for pending-reboot age.

**8. ufw baseline has no rate-limit / logging / v6 assertion (`modules/00-os/ufw-firewall/apply.sh:67-71`, `verify.sh`)**
No `ufw limit` template for later SSH allow rules, `ufw logging` unset (default low → thin forensics), and `IPV6=yes` in `/etc/default/ufw` not verified. If a downstream module opens SSH, brute-force lands on default sshd `MaxAuthTries 6` with no fail2ban.

**9. `unattended-upgrades` origin list is broader than security (`modules/00-os/kubuntu-baseline/apply.sh:190-197`)**
Includes `${distro_id}:${distro_codename}` and `-updates` alongside `-security`. Non-security regressions ship automatically. If stability > breadth is preferred, restrict to `-security` + ESM.

**10. `sudo -v` babysit terminal is a footgun with unlockable host (`keepalive.sh:53-56`)**
Given item 5 (host never auto-locks), any process reading `TTY`-associated sudo cache reaches root while the babysit terminal runs. Documented, but combined with the no-lock state the window is wide. Consider requiring screensaver lock or a max session TTL in the loop.

## Lower / hygiene

**11. `ssh-client` fixup misses non-standard private-key names (`modules/00-os/ssh-client/apply.sh:78-82`)** — chmod covers `id_*`, `*.pem`, `authorized_keys`, `known_hosts`. A key called `github_deploy` stays at whatever mode git-clone left. Optional: detect PEM header instead of name.

**12. Snapshot files written under `$HOME/system-info` inherit user umask (`modules/00-os/ssh-server/apply.sh:81-87`)** — `sshd -T` output is not secret, but `install -m 0600` would be more consistent with the rest of the ~/.ssh regime.

**13. `verify.sh` scripts require cached sudo (`modules/00-os/ssh-server/verify.sh:35`, `ufw/verify.sh:31`)** — makes automated post-boot verification harder; consider running the sudo-only checks conditionally.

**14. No AppArmor / audit / kernel-lockdown baseline** — module 0 skips these entirely. If the daily host runs untrusted agent code, adding a check that AppArmor is `enforcing` and the current kernel supports lockdown would tighten the baseline.

**15. Empty `git-identity` directory (`modules/00-os/git-identity`)** — stub with no README. Either delete or land a placeholder; leaves security-relevant identity setup ambiguous.

Highest-priority fixes: **#1, #2, #6** (real lockout / bypass windows) and **#3** (blast radius inside guest).

## Observations

- `_plans/open/2026-09-15-modular-box-setup.md` is the module-implementation checklist; it does not cover any of these hardening items — no overlap.
- `modules/00-os/git-identity/` is empty (finding #15).
- Working tree has unrelated modifications in `agents/skills/plan-init/` (not tied to this review).

---

Also see `_plans/README.md` and the project `README.md` for any rules that apply.
