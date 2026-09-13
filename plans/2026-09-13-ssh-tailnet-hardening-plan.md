# Plan: key-only SSH over the tailnet

**Status:** docs landed 2026-09-13. Live host `sshd` / `blade-14` join remains
`infra/tailscale/ssh.md`. Do not apply those from this file.

## Outcome

Make the physical host and persistent agent VM safely reachable with standard OpenSSH over
Tailscale. Authentication is exclusively by SSH public key. Neither machine exposes SSH to the
LAN or public Internet.

This is the reusable machine-side design. Windows-specific key generation and VS Code setup belong
in `dave.box-setup`, not in this repository.

## Decisions

- Use standard OpenSSH transported over Tailscale, not Tailscale SSH.
- Do not use Tailscale Funnel, a router port forward, UPnP, or a public port 22.
- Permit `publickey` authentication only. Disable password and keyboard-interactive authentication
  and prohibit root login.
- Keep client private keys on their originating clients. Install only public keys in
  `authorized_keys`.
- Bind a device-specific client key to that client's exact Tailscale IPv4 address with an
  `authorized_keys` `from=` restriction. Bind the host-to-guest automation key to the physical
  host's exact libvirt bridge address.
- Keep SSH host keys unique per machine and verify their fingerprints out of band on first use.
- Enforce network reachability in both the machine firewall and the Tailscale access policy.
- Apply changes in a lockout-safe order: install key, test a second connection, validate server
  configuration, reload, apply firewall restrictions, then test another fresh connection.

## Network boundary

The physical host accepts TCP/22 only through `tailscale0`.

The persistent guest accepts TCP/22 through:

1. `tailscale0`, for approved remote clients; and
2. the private libvirt interface, only from the physical host's libvirt bridge address
   (`192.168.122.1` in the current installation).

The narrow libvirt exception is required for host-driven guest bootstrap, recovery, and disposable
backup-restore tests. It does not make the guest reachable from the LAN. Do not allow the whole
`192.168.122.0/24` source range when a rule for the single hypervisor address is sufficient.
The host-to-guest key must carry the same single-address restriction in the guest's
`authorized_keys`. This path remains independent of Tailscale and retains interactive shell, PTY,
sudo automation, and TCP forwarding capability.

The guest's copied firewall rules affect restore-test clones. Preserve a recovery path that can stop
or mask the cloned `tailscaled` instance before it can contend with the primary VM's copied
Tailscale node identity. Test this explicitly as part of the backup proof.

## Current state to re-check at execution time

The last read-only inspection found:

- host `sshd` inactive with no TCP/22 listener;
- guest `sshd` active and listening on IPv4 and IPv6 wildcard addresses;
- guest UFW inactive; and
- Tailscale active on host and guest.

These are observations, not assumptions. Re-run service, socket, effective SSH configuration,
firewall, interface, and Tailscale-policy checks before changing anything.

## Phase 1: reconcile the documentation

1. Generalize SSH instructions in `machines/host/03-system-config.md` from a Windows-specific client
   to an approved client key.
2. Generalize `machines/vm/01-bootstrap.md` in the same way and document the single-host libvirt SSH
   exception.
3. Remove the Windows-specific Remote SSH section from `machines/common/04-ide+tooling.md`. Preserve
   the generic fact that Remote SSH provides read-write remote editing if it belongs in the shared
   guide. **Done 2026-09-13:** Windows client is
   `dave.box-setup/windows-box/host/05-vscode-remote-ssh.md`; the shared guide keeps a pointer only.
4. Update `machines/vm/03-networking.md` with the two permitted guest SSH paths and the explicit
   LAN/public deny boundary.
5. Update `machines/vm/07-snapshots.md` so a hardened restore-test clone remains
   manageable without joining Tailscale.
6. Update verification checklists without embedding Dave's client device names in this reusable
   repository.
7. Keep tailnet ACL/grant inventory and policy in the separate `infra/tailscale` documentation;
   link to it rather than duplicating live policy here.

Run the repository's forbidden-reference guards after removing the Windows-specific material from
`machines/host`, `machines/vm`, and `machines/common`.

## Phase 2: prepare approved client keys

For every approved client:

1. Use a dedicated Ed25519 key with a strong passphrase.
2. Record a descriptive key comment identifying the client and purpose.
3. Transfer only the `.pub` content through an authenticated or locally observed channel.
4. Record the client's exact Tailscale IPv4 address after it joins. Prefix its public-key line on
   each target with `from="CLIENT_TAILSCALE_IPV4",no-agent-forwarding,no-X11-forwarding`.
5. Add one public key per line to the target user's `~/.ssh/authorized_keys`. Do not add
   `restrict`, `command=`, `no-port-forwarding`, or `no-pty`: normal shells and VS Code Remote SSH
   forwarding must continue to work.
6. Set the directory to mode `700` and `authorized_keys` to `600`; verify ownership.
7. Do not remove the existing host-to-guest automation key. Identify its exact line by fingerprint
   or comment, confirm that direct host-to-guest SSH is using the libvirt path, then prefix that
   line with `from="HYPERVISOR_BRIDGE_IPV4",no-agent-forwarding,no-X11-forwarding`.
8. Test with password and keyboard-interactive fallback explicitly disabled on the client:

   ```bash
   ssh -o PasswordAuthentication=no \
     -o KbdInteractiveAuthentication=no \
     USER@TAILSCALE_NAME
   ```

Keep a working session and a local console or libvirt-console recovery path open throughout the
change. After applying each `from=` restriction, prove the allowed source still works. For the
host-to-guest key, also prove that the same key is rejected when the host targets the guest over its
Tailscale address instead of the libvirt address. Do not copy a remote client's private key to
another device merely to test its source restriction; inspect the exact `authorized_keys` entry and
use tailnet policy deny tests for other sources. Removing and rejoining a client node may change its
Tailscale IP and require both its policy host alias and `authorized_keys` entries to be updated.

## Phase 3: harden OpenSSH

Install `openssh-server` on the host only after at least one approved client public key is ready.
Back up the effective configuration and host-key fingerprints before changing it.

Create a managed drop-in such as `/etc/ssh/sshd_config.d/90-key-only.conf` on both targets with this
minimum policy:

```text
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
AuthenticationMethods publickey
PermitRootLogin no
PermitEmptyPasswords no
```

Before reload:

1. inspect `sshd -T` for conflicting vendor or cloud-init drop-ins;
2. run `sudo sshd -t` and stop if it reports any error;
3. reload rather than restart the service; and
4. establish a new key-authenticated session while the original session remains open.

Do not use `AllowUsers` until the actual Linux usernames and automation accounts are inventoried.
Do not bind `sshd` directly to a Tailscale address: firewall enforcement is more robust when
`tailscale0` is not yet ready during boot.

## Phase 4: enforce the machine firewalls

Before enabling or changing UFW, inventory current rules, defaults, Docker/libvirt interactions,
BB Serve, and any model-endpoint rule. Preserve required rules and default outbound access.

Target rules:

- host: allow inbound TCP/22 on `tailscale0`; deny it on every other interface;
- guest: allow inbound TCP/22 on `tailscale0`;
- guest: additionally allow inbound TCP/22 from only the hypervisor bridge address on the private
  libvirt interface; and
- both: default deny unsolicited inbound traffic.

Resolve actual interface names and addresses immediately before applying rules. Do not paste rules
that contain assumed interface names beyond the stable Tailscale interface. Verify IPv4 and IPv6.

After applying the rules, test new sessions over every allowed route and test representative denied
routes. Keep the recovery session open until all positive tests pass.

## Phase 5: tighten the tailnet policy

In `infra/tailscale`:

1. export and save the current non-secret access policy before editing;
2. after the administration client joins, record its exact Tailscale IPv4 address and define a
   device-specific host alias for it; do not tag a human-operated client or use a user selector that
   would authorize all of that user's devices;
3. add a narrowly scoped, separately documented TCP/22 grant from that client host alias to only
   the host and persistent guest;
4. ensure a broad allow-all rule does not make the narrow grant ineffective;
5. add permit and deny policy tests in the Tailscale policy editor;
6. preserve the explicitly intended TCP/443 access to the private BB Serve origins; and
7. confirm Funnel remains disabled.

Do not finalize a device selector before the administration client has joined the tailnet and its
exact address and host alias are known.

## Phase 6: verification and recovery proof

Verify all of the following:

- `sudo sshd -t` succeeds on host and guest.
- `sshd -T` reports public-key-only authentication and prohibited root login.
- Approved keys can open fresh sessions through the intended Tailscale names.
- Password-only and keyboard-interactive attempts fail.
- Host TCP/22 is unreachable through LAN/public interfaces.
- Guest TCP/22 is unreachable from LAN/public clients.
- The physical host can still reach the guest through the narrowly allowed libvirt path.
- The host-to-guest key fails when the physical host targets the guest over Tailscale instead of the
  libvirt path.
- Every device-specific client key line contains the correct exact-address `from=` restriction.
- Tailnet policy tests deny SSH from devices other than the approved administration client.
- VS Code-style SSH port forwarding works; the server must permit the forwarding Remote SSH needs.
- Reboot host and guest, then repeat service, firewall, Tailscale, and fresh-login checks.
- Boot a disposable backup overlay without attaching shared host folders, stop its copied Tailscale
  identity using the private management path, and prove the restore-test workflow still works.
- Run `./verify-setup.sh --host --operational` and the appropriate guest verification profile.
- Run Markdown lint, `git diff --check`, and the repository architecture guards.

## Documentation acceptance criteria

- Reusable docs contain no dependency on a particular Windows device.
- The host-only and guest libvirt firewall boundaries are unambiguous.
- The lockout-safe order is written once as the canonical procedure and linked where needed.
- Backup and restore instructions remain executable after SSH hardening.
- Live tailnet policy remains owned by `infra/tailscale`.

## Stop conditions

Stop without reloading SSH or enabling the firewall if any of these apply:

- no approved public key has passed a forced-public-key login test;
- `sshd -t` fails;
- the current firewall policy cannot be reconstructed safely;
- the Tailscale client identity or intended grant selector is ambiguous; or
- there is no tested console/recovery route.
