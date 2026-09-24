# kdenlive recipe

Run on a catalog-ticked daily host. Kdenlive is installed from the KDE publisher's `latest/stable`
Snap channel, not from Ubuntu's APT package.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/07-apps/kdenlive
sudo ./apply.sh
```

The script installs the Snap and connects `removable-media` so Kdenlive can use media on removable
volumes. The Snap can already read the desktop user's home directory, including host-only sync
files.

## Verify

```bash
./verify.sh
```

The verifier checks the installed Snap, its command, and the `removable-media` connection. Open a
representative clip manually to test the required codecs and export workflow.
