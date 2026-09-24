# dropbox-client recipe

Run on a catalog-ticked daily host. The official Dropbox desktop client and its synced files remain
on the host; they do not belong in agent or personal-browser guests.

## Download and apply

Download the current Ubuntu 64-bit package from Dropbox's
[Linux install page](https://www.dropbox.com/install-linux). Review the downloaded file, then pass
its absolute path to the installer:

```bash
cd ~/projects/agent-box-setup/modules/07-apps/dropbox-client
./apply.sh --package "$HOME/Downloads/dropbox_<version>_amd64.deb"
```

The script confirms that the selected Debian package declares itself as `dropbox`, then uses APT to
install it and any dependencies. It deliberately does not guess a versioned vendor URL or download
an executable unattended.

Start Dropbox from the application menu, complete the interactive sign-in, and choose the local sync
location. Keep the default `~/Dropbox` location unless the deployment overlay specifies a different
host-only location.

## Verify

```bash
./verify.sh
./verify.sh --authenticated
```

The first check confirms the client is installed. The authenticated check also requires a local
Dropbox directory; it does not inspect account contents or credentials.
