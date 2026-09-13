#!/usr/bin/env bash

# Copy each Klipper clipboard change into the XWayland clipboard.
# spice-vdagent only watches the X11 clipboard, so without this sync text copied
# in native Wayland apps never reaches the SPICE client on the host.  Only text
# that Klipper records is copied.

set -Eeuo pipefail

readonly klipper_signal="type='signal',interface='org.kde.klipper.klipper',member='clipboardHistoryUpdated'"

qdbus6 org.kde.klipper /klipper >/dev/null || {
    printf '%s\n' 'Klipper is not on the session bus; is Plasma running?' >&2
    exit 1
}

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

sync_clipboard() {
    # qdbus6 appends one newline; $(...) strips it, and any trailing newlines of
    # the copied text too, which is acceptable for text copy.
    local text
    text="$(qdbus6 org.kde.klipper /klipper org.kde.klipper.klipper.getClipboardContents)"
    [[ -n "$text" ]] || return 0
    printf '%s' "$text" >"$work_dir/klipper"

    # KWin syncs the X11 clipboard back into Wayland and Klipper; skip identical
    # content so the two clipboards cannot ping-pong.
    xclip -selection clipboard -out >"$work_dir/x11" 2>/dev/null || true
    cmp -s "$work_dir/klipper" "$work_dir/x11" && return 0

    xclip -selection clipboard -in <"$work_dir/klipper"
}

sync_clipboard
while IFS= read -r line; do
    [[ "$line" == *member=clipboardHistoryUpdated* ]] && sync_clipboard
done < <(dbus-monitor --session "$klipper_signal")

printf '%s\n' 'dbus-monitor exited.' >&2
exit 1
