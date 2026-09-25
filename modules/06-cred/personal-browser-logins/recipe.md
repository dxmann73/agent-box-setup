# personal-browser-logins recipe

Run only in the Chrome guest, after `chrome-vm-packages` and the browser-isolation acceptance tests.
This is one credential module because the personal URL list is a per-host overlay value, not a set
of catalog ticks.

1. Open Chrome in the guest and sign in to the accounts selected by the deployment overlay.
1. Confirm every required account has a usable session and no login has moved to the host browser.
1. Keep the guest off Tailscale. The host browser remains for local callbacks and utility setup.

The generic repository intentionally contains no personal URLs, account names, cookies, or browser
profile data. There is no verifier: session state cannot be safely or reliably inspected from a
shell script, and a missing session is obvious in use.
