#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "ERROR: losslesscut apply failed at line %s\n" "$LINENO" >&2' ERR

readonly module_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly appimage="$HOME/Applications/LosslessCut.AppImage"
readonly repo_desktop="$HOME/projects/agent-box-setup/user-home/applications/losslesscut.desktop"
readonly menu_desktop="$HOME/.local/share/applications/losslesscut.desktop"
readonly icon_rel="usr/share/icons/hicolor/512x512/apps/losslesscut.png"
readonly icon_target="$HOME/.local/share/icons/hicolor/512x512/apps/losslesscut.png"
readonly snap_config="$HOME/snap/losslesscut/current/.config/LosslessCut/config.json"
readonly appimage_config="$HOME/.config/LosslessCut/config.json"

usage() {
    cat <<'USAGE'
Usage: ./apply.sh

Installs LosslessCut as the upstream AppImage: FUSE 2 compatibility package, AppImage download
(update.sh), settings carried over from the old snap, snap removal, application-menu entry (symlink
into this repo) and the menu icon extracted from the AppImage.

~/update-tools.sh keeps the AppImage current afterwards.

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

[[ $EUID -ne 0 ]] || {
    printf '%s\n' 'Run as the normal user; sudo is used only for apt and snap.' >&2
    exit 1
}

[[ -f $repo_desktop ]] || {
    printf 'Missing %s; this checkout is incomplete.\n' "$repo_desktop" >&2
    exit 1
}

! pgrep -u "$UID" -x losslesscut >/dev/null || {
    printf '%s\n' 'LosslessCut is running. Close it and re-run.' >&2
    exit 1
}

if dpkg-query -W -f='${Status}' libfuse2t64 2>/dev/null | grep -q '^install ok installed$'; then
    printf '%s\n' 'libfuse2t64 already installed; skipping apt-get install.'
else
    sudo apt-get update
    sudo apt-get install -y libfuse2t64
fi

"$module_dir/update.sh"

if [[ -f $appimage_config ]]; then
    printf 'AppImage settings already present: %s\n' "$appimage_config"
elif [[ -f $snap_config ]]; then
    mkdir -p "$(dirname "$appimage_config")"
    cp "$snap_config" "$appimage_config"
    printf 'Settings copied from the snap: %s\n' "$appimage_config"
fi

# The snap bundles a 2018 Mesa that cannot drive current AMD GPUs; its GPU process fails and the main
# process segfaults. snapd keeps an automatic snapshot of the snap data on removal.
if snap list losslesscut >/dev/null 2>&1; then
    sudo snap remove losslesscut
    printf '%s\n' 'Snap losslesscut removed.'
fi

mkdir -p "$(dirname "$menu_desktop")"
if [[ -L $menu_desktop && $(readlink -f "$menu_desktop") == "$(readlink -f "$repo_desktop")" ]]; then
    printf 'Menu entry already linked: %s\n' "$menu_desktop"
else
    [[ ! -e $menu_desktop && ! -L $menu_desktop ]] || {
        printf 'Refusing to replace existing %s; remove it and re-run.\n' "$menu_desktop" >&2
        exit 1
    }
    ln -s "$repo_desktop" "$menu_desktop"
    printf 'Menu entry linked: %s -> %s\n' "$menu_desktop" "$repo_desktop"
fi

if [[ -f $icon_target ]]; then
    printf 'Icon already installed: %s\n' "$icon_target"
else
    extract_dir=$(mktemp -d)
    trap 'rm -rf "$extract_dir"' EXIT
    (cd "$extract_dir" && "$appimage" --appimage-extract "$icon_rel" >/dev/null)

    extracted="$extract_dir/squashfs-root/$icon_rel"
    [[ -f $extracted ]] || {
        printf 'AppImage did not yield %s; the bundle layout changed.\n' "$icon_rel" >&2
        exit 1
    }

    mkdir -p "$(dirname "$icon_target")"
    cp "$extracted" "$icon_target"
    printf 'Icon installed: %s\n' "$icon_target"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$(dirname "$menu_desktop")"
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" >/dev/null 2>&1 || true
fi

if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 >/dev/null 2>&1 || true
fi

printf '%s\n' 'losslesscut applied.'
