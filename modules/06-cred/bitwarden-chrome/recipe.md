# bitwarden-chrome recipe

Run only in the Chrome guest, after `personal-browser-logins`. Install the official Bitwarden Chrome
extension, sign in, unlock the vault, and set its vault timeout to **Never**. The host Bitwarden app
is a separate personal-host-app module; do not use it as a substitute for the guest extension.

```bash
cd ~/projects/agent-box-setup/modules/06-cred/bitwarden-chrome
./verify.sh --target chrome-vm --confirmed
```

The verifier checks the installed Chrome extension and requires an explicit confirmation of the
unlocked vault and timeout policy. It never reads vault data, cookies, or secret values.
