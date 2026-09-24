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
autostart entry, application-menu entry linked into this repo, menu icon installed, and expected BB
processes.

Requires BB to be running; does not start or stop it.

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

bb_appimage_healthy() {
    command_available curl && command_available jq || return 1
    curl --connect-timeout 2 --fail --max-time 5 --silent --show-error \
        http://127.0.0.1:38886/api/v1/system/version |
        jq -e '.currentVersion | strings | select(length > 0)' >/dev/null
}

appimage_process_running() {
    local -r pattern="$1"
    local pid executable

    while IFS= read -r pid; do
        executable=$(readlink -f "/proc/$pid/exe" 2>/dev/null || true)
        [[ $executable == /tmp/.mount_bb*/bb ]] && return 0
    done < <(pgrep -u "$UID" -f -- "$pattern" || true)

    return 1
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
check 'curl on PATH' command_available curl
check 'jq on PATH' command_available jq
check 'BB responds on port 38886' bb_appimage_healthy
check 'BB primary process is running' appimage_process_running 'bb-app/server/dist/index.js'
check 'BB daemon process is running' appimage_process_running 'host-daemon/dist/daemon-bundle.mjs'

if ((failures > 0)); then
    printf 'bb-appimage verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'bb-appimage verify passed'
