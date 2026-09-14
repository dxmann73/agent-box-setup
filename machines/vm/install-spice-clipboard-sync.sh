#!/usr/bin/env bash
# Stream into a Plasma Wayland guest to export text and PNG clipboard data to SPICE/X11.
set -Eeuo pipefail
[[ $EUID -ne 0 ]] || { echo 'Run as the desktop user.' >&2; exit 1; }
systemd-detect-virt --quiet || { echo 'Expected a virtualized guest.' >&2; exit 1; }
sudo -n true
if ! command -v wl-paste >/dev/null || ! command -v xclip >/dev/null; then
    sudo env DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 install -y wl-clipboard xclip
fi
sudo install -d -m 0755 /usr/local/libexec /etc/systemd/user
sudo tee /usr/local/libexec/spice-clipboard-export >/dev/null <<'HELPER'
#!/usr/bin/env bash
set -Eeuo pipefail
# Read the advertised type explicitly: xclip otherwise labels PNG bytes as text.
# Never log clipboard content.
[[ ${CLIPBOARD_STATE:-data} == data || ${CLIPBOARD_STATE:-data} == sensitive ]] || exit 0
types="$(wl-paste --list-types 2>/dev/null)" || exit 0
if grep -Fxq image/png <<<"$types"; then
    mime=image/png
elif grep -Fxq 'text/plain;charset=utf-8' <<<"$types"; then
    mime='text/plain;charset=utf-8'
elif grep -Fxq text/plain <<<"$types"; then
    mime=text/plain
else
    exit 0
fi
work_dir="$(mktemp -d "${XDG_RUNTIME_DIR:?}/spice-clipboard.XXXXXX")"
trap 'rm -rf -- "$work_dir"' EXIT
wl-paste --no-newline --type "$mime" > "$work_dir/wayland"
# KWin reflects X11 selections into Wayland. Comparing first prevents feedback.
if xclip -selection clipboard -target "$mime" -out > "$work_dir/x11" 2>/dev/null &&
    cmp -s "$work_dir/wayland" "$work_dir/x11"; then
    exit 0
fi
xclip -selection clipboard -target "$mime" -in < "$work_dir/wayland" >/dev/null 2>&1
HELPER
sudo chmod 0755 /usr/local/libexec/spice-clipboard-export
sudo tee /usr/local/libexec/spice-clipboard-watch >/dev/null <<'WATCHER'
#!/usr/bin/env bash
set -Eeuo pipefail
/usr/local/libexec/spice-clipboard-export
while IFS= read -r line; do
    if [[ "$line" == *member=clipboardHistoryUpdated* ]]; then
        /usr/local/libexec/spice-clipboard-export
    fi
done < <(dbus-monitor --session "type='signal',interface='org.kde.klipper.klipper',member='clipboardHistoryUpdated'")
exit 1
WATCHER
sudo chmod 0755 /usr/local/libexec/spice-clipboard-watch
sudo tee /etc/systemd/user/spice-clipboard-sync.service >/dev/null <<'SERVICE'
[Unit]
Description=Export Wayland text and PNG clipboard to SPICE
After=graphical-session.target spice-vdagent.service
PartOf=graphical-session.target
ConditionEnvironment=WAYLAND_DISPLAY

[Service]
Type=simple
ExecStart=/usr/local/libexec/spice-clipboard-watch
Restart=on-failure
RestartSec=2

[Install]
WantedBy=graphical-session.target
SERVICE
# Klipper must notify about image selections as well as text selections.
kwriteconfig6 --file klipperrc --group General --key IgnoreImages false
qdbus6 org.kde.klipper /klipper org.kde.klipper.klipper.reloadConfig
systemctl --user daemon-reload
systemctl --user enable spice-clipboard-sync.service
systemctl --user restart spice-clipboard-sync.service
systemctl --user is-active spice-clipboard-sync.service
