# kubuntu-desktop installer recipe

Use this recipe only at the OS installer stage. It creates the base desktop role; later modules own
baseline packages, SSH, sudo policy, repo clones, agent CLIs, credentials, guest integration, and
personal apps.

## Inputs

Get these values from the active box profile or deployment overlay before starting:

- target role: daily host, agent guest, or browser guest
- hostname
- first user name
- login password
- target disk

Do not record the password in this repo. Stop before erasing or repartitioning any disk whose role is
unclear.

## Install

1. Boot a verified Kubuntu ISO.
1. Start the graphical installer.
1. Use the profile hostname exactly.
1. Create the profile's first user.
1. Set the login password from the profile.
1. Install to the selected target disk as a fresh Kubuntu desktop system.
1. Reboot into the installed system and remove the installer media.

Use default Kubuntu desktop choices unless the profile explicitly says otherwise. Guest sizing,
autologin, lock policy, locale, wallet policy, package baselines, and SSH policy are later modules.

## Handoff

After first boot, run this module's verify script:

```bash
cd ~/projects/agent-box-setup
modules/00-os/kubuntu-desktop/verify.sh
```

When a profile value should be asserted:

```bash
KUBUNTU_DESKTOP_EXPECT_HOSTNAME=box-name \
KUBUNTU_DESKTOP_EXPECT_USER=user-name \
modules/00-os/kubuntu-desktop/verify.sh
```

Then continue with the next ticked modules from the catalog.
