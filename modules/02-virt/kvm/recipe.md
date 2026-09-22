# kvm recipe

Run this on daily hosts (`xhost`, `bhost`) after `kubuntu-baseline`. Not on guests. On those hosts
`host-sudo-session` provides the cached sudo the script needs.

`home-dotfiles` exports `LIBVIRT_DEFAULT_URI=qemu:///system` in `~/.bashrc` and `~/.profile`. This
module does not edit shell startup files. Apply and verify pass `qemu:///system` on every `virsh`
call.

This module is deliberately narrow: it makes libvirt usable and idempotently checks the stock
substrate. It does not express the final guest topology. Network isolation, guest definitions,
installation media, shares, snapshots, and backup are separate catalog modules and move during their
own recipe and cutover work.

## What apply does

- Refuses to run unless the machine is bare-metal `x86_64`.
- Requires `~/vms` from `kubuntu-baseline --target daily-host`. Does not create it.
- Installs `cpu-checker`, `qemu-system-x86`, `libvirt-daemon-system`, `libvirt-clients`, `virtinst`,
  `virt-manager`, `virt-viewer`, `virtiofsd`, and `libnss-libvirt`. QEMU runs
  `/usr/libexec/virtiofsd`. That binary is not on `PATH`.
- Runs `kvm-ok` and stops if KVM acceleration is unavailable.
- Adds the invoking user to the `libvirt` and `kvm` groups.
- Enables `libvirtd.service`.
- Places `libvirt` then `libvirt_guest` immediately after `files` on the single `hosts:` line in
  `/etc/nsswitch.conf`. Other resolver modules stay in their existing order. See
  [libvirt NSS](https://libvirt.org/nss.html).
- Ensures the `default` storage pool is a directory pool at `/var/lib/libvirt/images`, active and
  persistent, and set to autostart. If a pool named `default` already points somewhere else, apply
  stops instead of redefining it.
- Ensures libvirt's stock `default` network is NAT on `virbr0` at `192.168.122.1/24`, active and
  persistent, and set to autostart. Defines it from `/usr/share/libvirt/networks/default.xml` only
  when it is missing. If a network named `default` already differs, apply stops instead of
  redefining it. This keeps existing hosts stable while the modular tree is being built. It is not
  the final isolation model for agent or browser guests: `isolated-agent-net` and
  `isolated-browser-net` own those network policies later.
- Sets an uncommented `ON_SHUTDOWN=suspend` in `/etc/default/libvirt-guests`. Leaves a commented
  `ON_BOOT` line alone. `/usr/lib/libvirt/libvirt-guests.sh` sets `ON_BOOT=ignore` before sourcing
  that file. An uncommented `ON_BOOT` value other than `ignore` is replaced. `SHUTDOWN_TIMEOUT` and
  `PARALLEL_SHUTDOWN` are not changed.
- Enables `libvirt-guests.service` without restarting it. The unit's stop action managed-saves every
  running guest.

Changed copies of `nsswitch.conf` and `libvirt-guests` are saved under
`/var/backups/agent-box-setup-kvm-<timestamp>/` before they are replaced.

## Not this module

- Kubuntu ISO and `/var/lib/libvirt/boot`: `kubuntu-iso`. A libvirt pool named `boot` is not created
  or checked here.
- `isolated-agent-net` and `isolated-browser-net`: guest isolation policy, host nft rules, and any
  move away from the stock `default` network.
- `agent-vm`, `chrome-vm`, and guest bootstrap modules: domain XML, vCPU/RAM/disk values, firmware,
  display choices, install flow, and guest-side setup.
- `virtiofs-desktop-share`, `virtiofs-user-data-shares`, `vm-snapshots`, and `vm-disk-backup`:
  guest shares, rollback, and backup lifecycle.
- Shell `LIBVIRT_DEFAULT_URI`: `home-dotfiles`.
- UFW or service allow rules. Libvirt installs its own chains for the stock NAT network; per-service
  host or guest rules belong to the module that owns that service.

## Re-login

`usermod` does not change the current session. After the first apply, log out and back in so
`/dev/kvm` and `virsh` work without sudo, then run verify.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/02-virt/kvm
./apply.sh
```

## Verify

```bash
./verify.sh
```
