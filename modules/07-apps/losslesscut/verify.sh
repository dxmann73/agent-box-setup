#!/usr/bin/env bash
set -Eeuo pipefail

readonly appimage="$HOME/Applications/LosslessCut.AppImage"
readonly repo_desktop="$HOME/projects/agent-box-setup/user-home/applications/losslesscut.desktop"
readonly menu_desktop="$HOME/.local/share/applications/losslesscut.desktop"
readonly icon_target="$HOME/.local/share/icons/hicolor/512x512/apps/losslesscut.png"
readonly update_tools="$HOME/projects/agent-box-setup/user-home/update-tools.sh"

failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh

Checks the LosslessCut AppImage wiring on the host: AppImage present, FUSE 2 package installed, old
snap removed, application-menu entry linked into this repo, menu icon installed, and the weekly
update step present in update-tools.sh.

Offline check; does not compare against the latest GitHub release (run ./update.sh for that).

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

appimage_executable() {
    [[ -x $appimage ]]
}

fuse2_installed() {
    dpkg-query -W -f='${Status}' libfuse2t64 2>/dev/null | grep -q '^install ok installed$'
}

snap_removed() {
    ! snap list losslesscut >/dev/null 2>&1
}

menu_entry_linked() {
    [[ -L $menu_desktop ]] &&
        [[ $(readlink -f "$menu_desktop") == "$(readlink -f "$repo_desktop")" ]]
}

menu_entry_valid() {
    if command -v desktop-file-validate >/dev/null 2>&1; then
        desktop-file-validate "$menu_desktop"
    else
        [[ -f $menu_desktop ]]
    fi
}

menu_entry_execs_appimage() {
    grep -qxF "Exec=$appimage --no-sandbox %U" "$menu_desktop"
}

icon_installed() {
    [[ -s $icon_target ]]
}

weekly_update_wired() {
    grep -qF 'modules/07-apps/losslesscut/update.sh' "$update_tools"
}

check 'LosslessCut.AppImage present and executable' appimage_executable
check 'libfuse2t64 installed' fuse2_installed
check 'losslesscut snap removed' snap_removed
check 'menu entry is a symlink into this repo' menu_entry_linked

if menu_entry_linked; then
    check 'menu entry passes desktop-file-validate' menu_entry_valid
    check 'menu entry runs the AppImage' menu_entry_execs_appimage
fi

check 'menu icon installed' icon_installed
check 'update-tools.sh runs update.sh' weekly_update_wired

if ((failures > 0)); then
    printf 'losslesscut verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'losslesscut verify passed'
