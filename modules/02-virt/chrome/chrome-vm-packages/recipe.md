# chrome-vm-packages recipe

Run this inside the browser guest after `chrome-vm`, `guest-ssh-sudo-bootstrap`, and
`guest-integration`.

This module owns only browser-specific packages and apt policy:

- install the Google Chrome apt signing key and repository;
- install `google-chrome-stable`;
- add the Google Chrome origin to unattended upgrades;
- make sure apt daily timers are enabled.

It does not install OpenSSH, qemu guest integration, SPICE integration, locale settings, KDE theme
settings, Chrome startup URLs, browser logins, host launchers, shares, snapshots, or backup jobs.

The old `dave.box-setup` Chrome guest script did more in one pass. The modular split is deliberate:
`guest-ssh-sudo-bootstrap` owns SSH/sudo, `guest-integration` owns QEMU/SPICE packages, and later
Dave-scoped modules own personal browser behavior.

## Values

Deployment overlays own concrete hostnames. Export the expected browser guest hostname before
running `apply.sh` or `verify.sh`:

```bash
export CHROME_VM_EXPECTED_HOSTNAME=chrome-vm
```

If unset, the scripts default to `chrome-vm`, matching the current catalog profile.

## Apply

From inside the browser guest:

```bash
cd ~/projects/agent-box-setup/modules/02-virt/chrome/chrome-vm-packages
./apply.sh
```

For a guest that does not have this checkout, stream this module through an operator-controlled path
after SSH bootstrap.

`apply.sh`:

- refuses to run as root, outside a VM, without non-interactive sudo, or on an unexpected hostname;
- installs `ca-certificates`, `curl`, `gnupg`, and `unattended-upgrades`;
- installs the Google Linux signing key in `/usr/share/keyrings/google-chrome.gpg`;
- writes `/etc/apt/sources.list.d/google-chrome.list`;
- installs `google-chrome-stable`;
- writes `/etc/apt/apt.conf.d/51unattended-upgrades-google-chrome`;
- enables `apt-daily.timer` and `apt-daily-upgrade.timer`.

## Verify

Inside the browser guest:

```bash
cd ~/projects/agent-box-setup/modules/02-virt/chrome/chrome-vm-packages
./verify.sh
```

`verify.sh` checks the guest/hostname guard, Chrome package and command, Google apt key/list, Chrome
unattended-upgrades origin, and apt daily timers.

## Simplification Candidates

- The legacy overlay still mixes package install, locale/theme policy, autologin, and Chrome startup
  tabs. Consider splitting those remaining pieces into focused modules instead of rebuilding one
  large Chrome guest setup script.
- If every future browser guest uses the same expected hostname, the hostname environment could be
  dropped. For now it preserves the catalog/overlay split and leaves room for a Blade-specific guest
  name.
