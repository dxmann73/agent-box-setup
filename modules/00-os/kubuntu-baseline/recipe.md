# kubuntu-baseline recipe

Run this module after `kubuntu-desktop` and before tool, SSH, firewall, VM integration, agent, or
credential modules.

## Targets

Use one target per run:

- `daily-host`: no idle screen lock while working, lock on resume/lid reopen, no autologin, no
  passwordless sudo, host layout directories under `$HOME`
- `guest`: passwordless guest sudo, SDDM autologin, screen lock and display blanking disabled

All baseline boxes install unattended updates, restart affected services automatically, and show a
KDE dialog when `/var/run/reboot-required` appears. They never reboot automatically: a reboot can
kill running agent work. The operator reboots when no agent work is running.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/00-os/kubuntu-baseline
sudo ./apply.sh --target daily-host
```

or:

```bash
cd ~/projects/agent-box-setup/modules/00-os/kubuntu-baseline
sudo ./apply.sh --target guest
```

Locale defaults to `en_US.UTF-8`. Add profile locales without storing private profile data here:

```bash
KUBUNTU_BASELINE_LOCALES="en_US.UTF-8 extra_LOCALE.UTF-8" \
KUBUNTU_BASELINE_LANG=en_US.UTF-8 \
sudo ./apply.sh --target daily-host
```

## Verify

```bash
./verify.sh --target daily-host
```

or:

```bash
./verify.sh --target guest
```
