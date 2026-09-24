# bitwarden-snap recipe

Run on a catalog-ticked daily host. This installs Bitwarden's desktop app for host-native apps. The
personal browser guest, if selected, owns its separate Bitwarden browser extension and vault timeout
setting.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/07-apps/bitwarden-snap
sudo ./apply.sh
```

Open Bitwarden from the application menu and complete its interactive sign-in. Do not put account
credentials or a master password into a script.

## Verify

```bash
./verify.sh
```

The normal verifier checks installation. Add `--authenticated` after sign-in to also require the
desktop app's local configuration directory; it does not inspect secrets or claim that the vault is
unlocked.
