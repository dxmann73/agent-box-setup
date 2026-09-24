# firefox-stock recipe

Run on a catalog-ticked daily host. Firefox stays installed as the stock host browser for captive
portals, local callbacks, setup, and other utility browsing. Personal daily browsing belongs in the
separate browser guest when the deployment selects one.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/07-apps/firefox-stock
sudo ./apply.sh
```

The script installs Ubuntu's Firefox Snap. It does not set Firefox as the default URL handler; the
deployment browser policy owns that decision.

## Verify

```bash
./verify.sh
```

The verifier checks that the Firefox Snap and its command are available.
