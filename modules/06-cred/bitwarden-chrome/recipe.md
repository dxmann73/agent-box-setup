# bitwarden-chrome recipe

Run only in the Chrome guest, after `personal-browser-logins`. Install the official Bitwarden Chrome
extension, sign in, unlock the vault, and set its vault timeout to **Never**. The host Bitwarden app
is a separate personal-host-app module; do not use it as a substitute for the guest extension.

There is no verifier. Vault state cannot be inspected without reading secret data, and a missing or
locked extension is obvious in use.
