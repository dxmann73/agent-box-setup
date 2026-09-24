# bb-client recipe

Run on a catalog-ticked remote daily host after `tailscale`. BB client access is the remote web app
or installed browser app pointed at the private Tailscale Serve origin defined in `infra`; it does
not install a second BB server or a guest-side npm fallback.

Open the approved `infra` origin in the daily host's browser and install it as an app if desired.
Keep the source URL out of this repository. Verify the private route by passing that URL directly:

```bash
./verify.sh --target daily-host --url 'https://bb.example.ts.net'
```

Then confirm in the UI that the shared host and enrolled execution machine are selectable.
