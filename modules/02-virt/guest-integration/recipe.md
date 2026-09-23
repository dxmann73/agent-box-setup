# guest-integration recipe

Run this inside a Kubuntu guest after `guest-ssh-sudo-bootstrap` proves key-only SSH and
passwordless sudo. This module applies to both guest roles: the agent VM and the Chrome VM.

This module owns only guest/host desktop integration:

- install and enable `qemu-guest-agent`;
- install and enable SPICE guest integration;
- install the Plasma Wayland clipboard bridge that exports plain text and PNG selections to the
  SPICE/X11 clipboard.

It does not install Chrome, agent CLIs, Playwright, BB, Tailscale, project repositories, credentials,
shared folders, snapshots, or backup jobs.

## Apply

From the host after SSH bootstrap:

```bash
ssh GUEST_HOSTNAME 'cd ~/projects/agent-box-setup/modules/02-virt/guest-integration && ./apply.sh'
```

For a guest that does not have this checkout yet, stream only this module through an
operator-controlled path. The script refuses to run as root or outside a virtualized guest and
requires non-interactive sudo.

`apply.sh`:

- installs `qemu-guest-agent`, `spice-vdagent`, `dbus-bin`, `wl-clipboard`, and `xclip`;
- enables and starts `qemu-guest-agent` and `spice-vdagentd`;
- installs root-owned clipboard helper scripts under `/usr/local/libexec`;
- installs `/etc/systemd/user/spice-clipboard-sync.service`;
- enables Klipper image history when a graphical Plasma session is available;
- disables the older text-only `klipper-clipboard-sync.service` if it is enabled or active;
- enables the user service and starts it when the graphical user session is already active.

The bridge listens for Klipper clipboard updates and copies only plain text or PNG payloads from the
Wayland clipboard into the X11 clipboard that SPICE watches. It does not log clipboard content.

Do not also enable the older text-only `klipper-clipboard-sync` service. Use one clipboard bridge per
guest.

## Verify

Inside the guest:

```bash
cd ~/projects/agent-box-setup/modules/02-virt/guest-integration
./verify.sh
```

If the graphical session is active, `verify.sh` expects the user service to be active. Without an
active graphical session, it checks that the service is enabled for the next login.

From the host, also check the QEMU guest agent command channel:

```bash
virsh qemu-agent-command GUEST_DOMAIN '{"execute":"guest-ping"}'
```

Then prove real clipboard behavior through a focused viewer:

- host to guest plain text;
- guest to host plain text;
- host to guest PNG image;
- guest to host PNG image, copied from a native Wayland application as well as the browser when the
  guest has one.

Compare rendered pixels for image tests, not PNG file bytes, because clipboard tools may re-encode
the image.

## Simplification Candidates

- The legacy agent baseline still enables `klipper-clipboard-sync`, while this module installs the
  newer PNG-capable `spice-clipboard-sync`. During cutover, consider removing the old text-only
  helper from the baseline and keeping this module as the single clipboard owner.
- `chrome-vm-packages` currently installs `qemu-guest-agent` and `spice-vdagent` in the overlay.
  After this module is in the host sequence, move those package responsibilities here and let Chrome
  package setup own only browser-specific packages and policy.
- The manual `virsh qemu-agent-command` check could become a host-side verify wrapper once the
  catalog runner knows the owning domain name for each guest.
