#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

trap 'printf "ERROR: guest-integration apply failed at line %s\n" "$LINENO" >&2' ERR

usage() {
    cat <<'USAGE'
Usage: ./apply.sh

Run inside the Kubuntu guest as the desktop user after guest-ssh-sudo-bootstrap.

Options:
  -h, --help   Show this help
USAGE
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h | --help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown argument: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

[[ $EUID -ne 0 ]] || die 'Run as the desktop user, not as root.'
systemd-detect-virt --vm --quiet || die 'This module applies inside a guest VM only.'

for binary in grep install mktemp sudo systemctl; do
    command -v "$binary" >/dev/null 2>&1 || die "Missing required command: ${binary}"
done

sudo -n true || die 'Passwordless sudo is required before this module runs.'

sudo env DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 update
sudo env DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Lock::Timeout=300 install -y \
    dbus-bin \
    qemu-guest-agent \
    spice-vdagent \
    wl-clipboard \
    xclip

sudo systemctl enable --now qemu-guest-agent spice-vdagentd

sudo install -d -m 0755 /usr/local/libexec /etc/systemd/user
sudo install -m 0755 /dev/stdin /usr/local/libexec/spice-clipboard-export <<'HELPER'
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

wl-paste --no-newline --type "$mime" >"$work_dir/wayland"

# KWin reflects X11 selections into Wayland. Comparing first prevents feedback.
if xclip -selection clipboard -target "$mime" -out >"$work_dir/x11" 2>/dev/null &&
    cmp -s "$work_dir/wayland" "$work_dir/x11"; then
    exit 0
fi

xclip -selection clipboard -target "$mime" -in <"$work_dir/wayland" >/dev/null 2>&1
HELPER

sudo install -m 0755 /dev/stdin /usr/local/libexec/spice-clipboard-watch <<'WATCHER'
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

sudo install -m 0644 /dev/stdin /etc/systemd/user/spice-clipboard-sync.service <<'SERVICE'
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

if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file klipperrc --group General --key IgnoreImages false || true
fi
if command -v qdbus6 >/dev/null 2>&1; then
    qdbus6 org.kde.klipper /klipper org.kde.klipper.klipper.reloadConfig >/dev/null 2>&1 || true
fi

systemctl --user daemon-reload
if systemctl --user is-enabled --quiet klipper-clipboard-sync.service 2>/dev/null ||
    systemctl --user is-active --quiet klipper-clipboard-sync.service 2>/dev/null; then
    printf '%s\n' \
        'Disabling older text-only klipper-clipboard-sync.service; using spice-clipboard-sync.' >&2
    systemctl --user disable --now klipper-clipboard-sync.service
fi
systemctl --user enable spice-clipboard-sync.service
if systemctl --user is-active --quiet graphical-session.target; then
    systemctl --user restart spice-clipboard-sync.service
fi

printf '%s\n' 'guest integration applied'
