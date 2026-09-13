# Personal browser VM plan

**Status:** proposal; clarify the questions below before implementation.
**Date:** 2026-09-13.
**Scope:** box-level host setup and a separate personal browser guest.

## Goal

Move personal Chrome browsing off the Kubuntu host so that a malicious website is contained
within a replaceable VM. Make links clicked in host applications open inside that boundary.
Remove Chrome from the host after the replacement workflow has been verified.

The current [architecture specification](../docs/specification/agent-box.md) explicitly places
Chrome on the host. Update that decision as part of implementing the agreed design.

## Proposed design

- Use the existing KVM/libvirt infrastructure to create a dedicated personal browser VM.
  Keep personal browser profiles and credentials separate from the coding-agent VM.
- Preferred arrangement: a persistent personal browser VM for everyday logged-in browsing,
  plus disposable browser sessions for links opened from email and other applications.
  This is a recommendation, not an agreed requirement.
- Simpler alternative: one persistent browser VM with a documented clean rebuild procedure.
  Another option is disposable-only browsing, accepting repeated logins and lost session state.
- Start with a minimal supported Linux desktop, Chrome, approximately 4 vCPUs and 4–8 GiB RAM
  per running browser guest. Measure responsiveness and resource use before finalizing sizing.
- Use a local VM viewer. Initially disable automatic clipboard sharing, file sharing, drag and
  drop, USB redirection, and GPU passthrough. Evaluate any needed integration individually.
- Give browser guests internet access on a dedicated virtual network. Enforce restrictions on
  the host to prevent access to host services, the agent VM, the LAN, and the tailnet, with only
  explicit exceptions and required network infrastructure traffic allowed.
- Keep downloads inside the guest by default. Provide deliberate export and upload workflows
  without exposing the host home directory or Dropbox tree.

## Questions to clarify

1. **Email:** Is mail read in a host desktop application or in Chrome as webmail? Which app or
   service? If webmail is inside the persistent VM, its links need their own routing mechanism
   to reach a disposable guest; changing the host default browser alone will not cover them.
1. **Persistence:** Prefer a persistent browser, disposable-only browsing, or the proposed
   combination? Should a disposable guest be created per link, per browsing session, or on demand?
1. **Link routing:** Should all external links go to a disposable browser, including links from
   chat, documents, and development tools? How should links requiring an existing login be handled?
1. **Accounts and profile migration:** Which Google accounts, bookmarks, extensions, saved tabs,
   and history should move? Should Chrome Sync be enabled, and for which data categories?
1. **Passwords and authentication:** How is Bitwarden used today? Are passkeys, hardware security
   keys, desktop-app OAuth callbacks, or other host integrations required?
1. **Files:** How often are files uploaded from host documents or Dropbox, or downloaded for host
   use? Which attachment types should also be opened in a disposable guest?
1. **Clipboard:** Is manual transfer sufficient, or is clipboard sharing essential? What access
   between host and guest is acceptable for the actual workflow?
1. **Media and desktop experience:** Are webcam calls, microphone access, screen sharing, DRM
   streaming, multiple monitors, printing, or GPU-heavy websites required?
1. **Private services:** Must personal browsing reach local development servers, BB, a NAS,
   router administration, or tailnet services? Identify narrow exceptions and their destination VM.
1. **Lifecycle:** Should the persistent VM start at login? What startup delay is acceptable for
   disposable browsing? What should closing the viewer do to running sessions?
1. **Recovery and retention:** Which persistent browser data needs backup, where should it live,
   and how much recent state can be lost? When should the old host profile be deleted?

## Work to do

### 1. Inspect the host and settle the design

- Confirm installed virtualization tools, available resources, host firewall configuration,
  browser installations, default URL handlers, and the actual mail/link-opening workflow.
- Resolve the questions that affect isolation, persistence, credentials, and essential usability.
- Record the chosen guest names, OS, resource limits, network policy, and session lifecycle.
- Define explicit exceptions for host integrations before enabling them.

### 2. Build the browser guest and recovery baseline

- Create a minimal browser-specific guest setup; do not apply the agent toolchain bootstrap.
- Keep Chrome's own sandbox enabled and configure guest OS and browser security updates.
- Retain libvirt/QEMU confinement on the host and keep the host virtualization stack updated.
- Build a clean baseline before personal logins or ordinary browsing, then test recreation.
- For disposable browsing, use a protected baseline with a separate writable disk overlay per
  session. Discard session state after shutdown, including any saved memory or auxiliary writable
  state. Define cleanup after crashes and host reboots, without deleting active sessions.
- Document updating and replacing the baseline so resets do not repeatedly restore outdated
  software. Keep persistent-profile backups separate from the clean baseline.

### 3. Enforce isolation and deliberate transfers

- Configure a dedicated virtual network and host-enforced ingress and egress rules. Account for
  IPv4, IPv6, DNS, DHCP, other guests, and private routes introduced by VPNs or Tailscale.
- Verify restrictions from inside the guest; ordinary NAT is insufficient for this policy.
- Remove unnecessary shared devices and channels; keep the viewer and management endpoints local.
- Implement the agreed upload/download transfer process and any limited clipboard integration.
  Exporting a file does not sanitize it; opening it on the host reintroduces exposure to that file.

### 4. Integrate link opening with the desktop

- Implement a host launcher that starts the appropriate guest and passes a URL to its browser.
- Treat URLs as untrusted data: allow only intended schemes, avoid shell interpolation, and
  handle quoting, multiple requests, guest startup, and delivery failures explicitly.
- Register the launcher as the default HTTP/HTTPS handler and browser desktop entry.
- If required, implement routing from webmail in the persistent guest to disposable sessions
  through a narrowly scoped request mechanism with no general host command execution access.
- Define behavior for localhost URLs and desktop authentication callbacks; test the chosen
  solution without broadly exposing host services to browser guests.
- Show useful errors if the VM cannot start or receive a URL; do not silently open it on the host.

### 5. Migrate daily browsing and retire host Chrome

- Migrate only the agreed profile data and credentials; do not seed disposable guests with the
  persistent profile, login cookies, or password vault.
- Exercise everyday tasks before changing the default handler permanently.
- Remove host Chrome once URL routing, authentication, and required browser features work.
- Check remaining host browsers and embedded browser behavior so external links follow the
  intended policy. Decide separately when to remove retained host profile data.

### 6. Update repository setup and verification

- Update the architecture specification and README diagram, scope, and setup order.
- Put host creation, networking, launcher, and removal instructions under `machines/host/`.
  Put browser-guest instructions under a clearly distinguished section of `machines/vm/`;
  revise its agent-only assumptions so browser guests do not inherit agent setup requirements.
- Update host application and automatic-update instructions for Chrome's new location.
- Keep any tracked launcher or desktop configuration under `user-home/` symlinked into the home
  directory, following the repository convention.
- Add role-appropriate browser checks to verification without requiring coding-agent tools in
  the browser guest. Preserve directory-driven skill verification for agent targets.
- Reconcile setup scripts that install or verify host Chrome so future setup runs do not
  reinstall it. Run documentation checks and the repository's target-separation checks.

## Acceptance checks

- Links from the actual mail app and other agreed applications open in the intended guest,
  including when it is stopped. Webmail routing is verified if applicable.
- Browser guests cannot access host files, agent credentials, host management interfaces, or
  private network services beyond the documented exceptions; internet access still works.
- A disposable session's test files, cookies, and browser changes disappear in the next session.
  Normal exit, crash cleanup, and host reboot leave no reusable session state in the launch flow.
- Rebuilding the persistent browser VM from the clean baseline works; restoring approved personal
  data is a separate, documented action.
- Required password-manager, authentication, media, clipboard, and file-transfer workflows work.
- The host stays responsive while browser and agent VMs are active under representative load.
- Host Chrome is removed, the default handler remains functional after reboot, and setup
  verification reflects the new architecture.

## Recovery limits

A VM provides an additional security boundary, not a guarantee that the host cannot be compromised.
Resetting a guest cannot undo stolen passwords, session cookies, cloud data changes, or phishing.
If account compromise is suspected, revoke affected sessions and rotate credentials from a clean
environment. Do not restore a suspected compromised browser profile into a clean replacement.

Host mail rendering and embedded browsers remain separate exposure paths. The exact protection
provided depends on the agreed routing and attachment-handling policy.

## References

- [QEMU security model](https://www.qemu.org/docs/master/system/security.html)
- [Libvirt virtual network configuration](https://libvirt.org/formatnetwork.html#nat-based-network)
- [Qubes disposable browsing workflow](https://doc.qubes-os.org/en/latest/user/how-to-guides/how-to-use-disposables.html)
  as a design reference; this proposal uses the existing Kubuntu/KVM setup.
