#!/usr/bin/env bash
set -Eeuo pipefail

readonly appimage="$HOME/Applications/bb.AppImage"
readonly repo_desktop="$HOME/projects/agent-box-setup/user-home/applications/bb.desktop"
readonly menu_desktop="$HOME/.local/share/applications/bb.desktop"
readonly autostart_desktop="$HOME/.config/autostart/bb.desktop"
readonly icon_target="$HOME/.local/share/icons/hicolor/1024x1024/apps/bb.png"

failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh

Checks the BB desktop AppImage wiring on the host: AppImage present, FUSE 2 package installed,
autostart entry, application-menu entry linked into this repo, menu icon installed, bb CLI on PATH.

Does not start the app.

Options:
  -h, --help   Show this help
USAGE
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

check() {
    local -r label="$1"
    shift

    if "$@"; then
        printf 'ok - %s\n' "$label"
    else
        printf 'not ok - %s\n' "$label" >&2
        failures=$((failures + 1))
    fi
}

command_available() {
    command -v "$1" >/dev/null 2>&1
}

appimage_executable() {
    [[ -x $appimage ]]
}

fuse2_installed() {
    dpkg-query -W -f='${Status}' libfuse2t64 2>/dev/null | grep -q '^install ok installed$'
}

autostart_points_at_appimage() {
    [[ -f $autostart_desktop ]] && grep -qxF "Exec=$appimage" "$autostart_desktop"
}

menu_entry_linked() {
    [[ -L $menu_desktop ]] &&
        [[ $(readlink -f "$menu_desktop") == "$(readlink -f "$repo_desktop")" ]]
}

menu_entry_valid() {
    if command_available desktop-file-validate; then
        desktop-file-validate "$menu_desktop"
    else
        [[ -f $menu_desktop ]]
    fi
}

menu_entry_execs_appimage() {
    grep -qxF "Exec=$appimage" "$menu_desktop"
}

icon_installed() {
    [[ -s $icon_target ]]
}

check 'bb.AppImage present and executable' appimage_executable
check 'libfuse2t64 installed' fuse2_installed
check 'autostart entry runs the AppImage' autostart_points_at_appimage
check 'menu entry is a symlink into this repo' menu_entry_linked

if menu_entry_linked; then
    check 'menu entry passes desktop-file-validate' menu_entry_valid
    check 'menu entry runs the AppImage, not the bb CLI' menu_entry_execs_appimage
fi

check 'menu icon installed' icon_installed
check 'bb CLI on PATH' command_available bb

if ((failures > 0)); then
    printf 'bb-server verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'bb-server verify passed'
