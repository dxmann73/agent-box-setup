# BB AppImage updates

Start BB from the app-menu entry or `~/Applications/bb.AppImage`. Apply updates from the app's
update screen after a popup appears.

The AppImage updater needs permission to replace its file. When `~/Applications` is not writable,
the desktop app can report an update without installing it. Check the app update screen after a
popup instead of assuming the update completed.

## Check a failed start

Run these commands before reinstalling anything:

```bash
curl -fsS http://127.0.0.1:38886/api/v1/system/version
ss -ltnp 'sport = :38886'
ss -ltnp 'sport = :38887'
pgrep -a -f 'bb.AppImage|\.mount_bb|bb-app|bb-server|bb-host-daemon'
tail -80 ~/.bb/logs/server-stdio.log
tail -80 ~/.bb/logs/host-daemon-stdio.log
```

Port `38886` is the BB service; `38887` is the host daemon. A process already listening on
`127.0.0.1:38886` explains `EADDRINUSE` and prevents BB from starting.

`./verify.sh` requires BB to be running, then checks the health endpoint and expected BB processes.
It does not start or stop BB. During the modular move, the large top-level `verify-setup.sh` remains
untouched.

## Upstream reference

- [BB desktop AppImage](https://github.com/get-bb/bb/blob/main/apps/desktop/README.md)
