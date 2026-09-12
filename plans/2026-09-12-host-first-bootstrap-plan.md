# Host-first bootstrap implementation plan

## Purpose

Implement the approved host-first flow in
`2026-09-12-remote-first-bootstrap-design.md`: a user starts one supervised
agent from a browser-readable document, that agent completes the physical host,
then it creates and configures the guest remotely without any guest provider or
GitHub authentication.

## 1. Browser bootstrap entry point

### Files

- Add `START-HERE.md` at the repository root.
- Update `README.md`.

### Changes

1. Make `START-HERE.md` self-contained when rendered on GitHub. It must state
   that it is only for a fresh Kubuntu host, choose one bootstrap agent, install
   it using its documented prerequisite/downloader, perform its provider login,
   and give the first supervised prompt.
1. Have that prompt clone this repository beneath `~/projects`, identify the
   machine as the host, follow the host path in order, request confirmation for
   optional tools and personal decisions, and not create the guest until the
   host completion checkpoint succeeds.
1. Link the entry point prominently from the README and replace the generic
   agent-led bootstrap text with the host-first sequence.
1. Remove any README wording that says host machine setup ends before the
   project-manager inventory is reconciled. Keep
   `clackworks.agents/project-manager/inventory.md` as the authoritative
   project inventory and `projects.code-workspace` as its workspace output.

### Verification

- A reader with no local clone can follow the document through starting a
  supervised host agent.
- The document contains no guest-login, host-passwordless-sudo, or manual VM
  preparation prerequisite.

## 2. Shared locale profile and home links

### Files

- Add `machines/common/01-localization.md`.
- Add `user-home/plasma-localerc`.
- Update `machines/common/00-home-environment.md`.
- Update `README.md` config-file inventory.
- Update `verify-setup.sh`.

### Changes

1. Track the canonical Plasma profile with `LANG=en_US.UTF-8`, every regional
   category set to `de_DE.UTF-8`, and `LANGUAGE=en_US` under `[Translations]`.
1. Document generating both locales and setting system defaults for the same
   categories. Link the tracked profile to `~/.config/plasma-localerc`; never
   rely on KDE Settings clicks for this result.
1. Add the Plasma configuration file to the existing symlink procedure and
   verification. Preserve the rule that all `user-home/` configuration is
   symlinked, never copied.
1. Check generated locales, category values, the Plasma translation setting,
   and the expected symlink in the relevant verification profiles.

### Verification

- `locale -a` includes `en_US.utf8` and `de_DE.utf8`.
- `locale` reports English UI and German regional categories.
- The Plasma locale file is the tracked symlink and has the agreed values.

## 3. Host baseline and host-only desktop policy

### Files

- Refactor `machines/host/prepare-host-system.sh`.
- Update `machines/host/01-hardware-validation.md`.
- Update `machines/host/03-system-config.md`.
- Update `machines/host/04-dev-and-agents.md`.
- Update `machines/host/05-hypervisor.md`.

### Changes

1. Narrow `prepare-host-system.sh` to deterministic privileged host baseline
   work: validated normal-user discovery, apt prerequisites, locale generation
   and defaults, required services, host firewall baseline, and libvirt setup.
   Retain strict error handling, idempotency, configuration backups where files
   are changed, and noninteractive package installation. Do not create a VM.
1. Ensure every potentially destructive configuration change is backed up or
   made only after a precise state check. Preserve existing inbound firewall
   exceptions and do not add a host `NOPASSWD` sudo rule.
1. Move physical-host power, suspend, display arrangement/resolution,
   screensaver/lock, and session policy into the host guides. Give commands for
   deterministic settings where available and label hardware/personal choices
   that need user confirmation.
1. Make the host completion gate explicit in the host order: locales and
   dotfiles, development tooling, all four agents, VS Code settings and
   keyboard shortcuts, host BB AppImage, and the complete project-manager
   checkout/update workflow must succeed before `05-hypervisor.md` starts VM
   creation.
1. Retain Docker’s VM-only restriction and the separate local-llm repository
   boundary.

### Verification

- Re-running the script produces no unintended changes and does not need
  unsupervised elevation.
- Host verification confirms the locale profile, supervised host security
  posture, four agent CLIs, VS Code configuration/shortcuts, and complete
  permanent host workspace before it permits the guest phase.

## 4. Pi lifecycle and target-specific authentication

### Files

- Update `agents/pi/README.md`.
- Update `agents/README.md`.
- Update `machines/host/04-dev-and-agents.md`.
- Update `machines/vm/02-dev-and-agents.md`.
- Update `machines/vm/05-credentials.md`.
- Update `machines/common/08-auto-updates.md`.
- Update `verify-setup.sh`.

### Changes

1. Keep Pi’s official npm install command:

   ```bash
   npm install -g --ignore-scripts @earendil-works/pi-coding-agent
   ```

1. Document `~/.pi/agent/settings.json` as global settings, the global
   `AGENTS.md` and skills links, `/login` for subscription or API-key setup,
   and `~/.pi/agent/auth.json` as Pi-managed credential state. Do not add
   credentials to the repository or link credentials from `user-home/`.
1. Use `pi update --self` for the Pi CLI and `pi update --all` only when Pi
   packages are intentionally managed. Integrate the selected update command
   into the weekly tooling update path without bypassing its normal error
   reporting.
1. Require host Pi authentication during host completion. Install and configure
   Pi on the guest during baseline provisioning, but move its guest `/login`
   step to the explicit VM credentials phase, alongside guest GitHub and other
   provider credentials.
1. Split verification of Pi installation/configuration from verification of Pi
   authentication so the credential-free guest bootstrap can pass.

### Verification

- `pi --version` works and Pi global instruction/skill links resolve on both
  machines.
- Host operational/full verification confirms its selected Pi authentication.
- Guest bootstrap verification does not inspect or require `auth.json`; guest
  full verification does after credentials are explicitly enabled.

## 5. SSH-driven guest baseline and guest desktop policy

### Files

- Add a guest-baseline script under `machines/vm/`.
- Update `machines/vm/01-bootstrap.md`.
- Update `machines/vm/02-dev-and-agents.md`.
- Update `machines/vm/03-networking.md` as needed to distinguish baseline
  networking from credential/network-exposure setup.
- Update `machines/vm/04-bb.md`.
- Update `machines/vm/05-credentials.md`.
- Update `machines/vm/07-snapshots.md`.
- Update `machines/host/05-hypervisor.md` with the invocation boundary.

### Changes

1. Replace the guest-console-led sequence with a short, explicit console
   bootstrap: install SSH, add the host public key, verify host-to-guest SSH,
   configure guest-only passwordless sudo, and then hand control to the host.
1. Add an idempotent guest-baseline script that the host invokes over SSH. It
   must validate that it is running in the expected guest context and that the
   remote user has guest `NOPASSWD` sudo before making privileged changes.
1. Put deterministic guest configuration in that script or its invoked guides:
   locale profile and dotfile links, packages and toolchain, four agent CLIs
   without provider login, browser/Playwright, BB service, QEMU guest agent,
   and guest desktop/session defaults.
1. Group guest-only blanking, lock, autologin, virtual display scale, SPICE,
   and guest-agent instructions under one guest desktop/session concern. Keep
   them separate from the host’s personal security and hardware policy.
1. Remove the existing first-Claude-login and GitHub-authentication gates from
   the bootstrap sequence. Credentials, Firecrawl, Tailscale, model access,
   shares, and external BB exposure remain in their dedicated later guides.
1. Keep `clean-guest` credential-free. Update the snapshot guide so restoring
   it is the test entry point after the revised scripts and documentation are
   ready, not an implementation-time action.

### Verification

- A host SSH session can run the guest baseline without a guest Claude, Codex,
  Pi, GitHub, Firecrawl, Tailscale, or model credential.
- A rerun is idempotent and leaves a reachable SSH guest, working QEMU guest
  agent, configured desktop/session baseline, toolchain, browser automation,
  and BB service.

## 6. Profiled verification

### Files

- Refactor `verify-setup.sh`.
- Update `README.md` verification section.
- Update target guide verification commands and checklists.

### Changes

1. Add a profile selector in addition to target selection: `bootstrap`,
   `operational`, and `full`. Preserve safe target auto-detection only when the
   explicit target is absent.
1. Define `bootstrap` as credential-free deterministic readiness. On the host,
   it covers baseline system state; on the guest, it covers SSH-driven setup,
   tools, agents installed/configured, locale, desktop/session, Playwright,
   and BB without provider credentials.
1. Define `operational` as the required host completion gate: all four
   authenticated host agents, VS Code settings/shortcuts, BB AppImage, and the
   project-manager workspace inventory. It may validate configured guest
   services but must not require guest provider credentials.
1. Define `full` as operational state plus explicitly enabled target-specific
   credentials, remote access, optional tools, and shares.
1. Preserve directory-driven skill discovery. Add clear pass/fail/skip output
   and non-zero exit status when required checks fail, while deferred profile
   checks are reported as skipped rather than failures.

### Verification

- `./verify-setup.sh --host --operational` succeeds before guest creation.
- `./verify-setup.sh --vm --bootstrap` succeeds after SSH provisioning and
  before guest credentials.
- `./verify-setup.sh --vm --full` has explicit checks for each later-enabled
  credential or optional capability.

## 7. Documentation consistency and exercise

### Files

- Update all affected README files, numbered guides, and checklists named
  above.
- Update `agents/README.md` and `verify-setup.sh` together when agent skill
  linking or verification changes.

### Changes

1. Reconcile cross-links, setup order, target labels, and checklists so they
   describe one host-first path without implying a manual guest agent login.
1. Check the source-of-truth specification after each documentation change;
   keep the VM as the unrestricted execution boundary and host agents
   supervised.
1. Run both repository policy greps from `AGENTS.md` to ensure native guides
   remain free of migration and WSL instructions.
1. After implementation review, restore `clean-guest` and execute the new
   host-driven guest path as a disposable acceptance test. Do not do this
   before the documentation and scripts are ready for review.

### Verification

- Markdown links and numbered setup order are coherent.
- Both policy greps are empty except for documented exemptions.
- The clean-guest exercise proves the acceptance checks in the design without
  introducing credentials into the baseline snapshot.

## Implementation order

1. Shared locale profile and its symlink/verification support.
1. Host baseline refactor and host desktop/session documentation.
1. Pi lifecycle and target-specific authentication documentation.
1. Guest SSH baseline script and guest desktop/session documentation.
1. Browser entry point, host workspace gate, and README flow.
1. Profiled verification refactor and all checklist/cross-link cleanup.
1. Static checks, script syntax checks, profile tests where possible, then the
   clean-guest acceptance exercise.
