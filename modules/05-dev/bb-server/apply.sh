#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "ERROR: bb-server apply failed at line %s\n" "$LINENO" >&2' ERR

readonly appimage="$HOME/Applications/bb.AppImage"
readonly repo_desktop="$HOME/projects/agent-box-setup/user-home/applications/bb.desktop"
readonly menu_desktop="$HOME/.local/share/applications/bb.desktop"
readonly autostart_desktop="$HOME/.config/autostart/bb.desktop"
readonly icon_rel="usr/share/icons/hicolor/1024x1024/apps/bb.png"
readonly icon_target="$HOME/.local/share/icons/hicolor/1024x1024/apps/bb.png"

usage() {
    cat <<'USAGE'
Usage: ./apply.sh

Wires the already-downloaded BB desktop AppImage into the session: FUSE 2 compatibility package,
KDE autostart entry, application-menu entry (symlink into this repo) and the menu icon extracted
from the AppImage.

Downloading ~/Applications/bb.AppImage is manual; see recipe.md.

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
    printf '%s\n' 'Run as the normal user; every path this module touches lives under $HOME.' >&2
    exit 1
}

[[ -f $appimage ]] || {
    printf 'Missing %s. Download the release AppImage first; see recipe.md.\n' "$appimage" >&2
    exit 1
}

[[ -x $appimage ]] || {
    printf 'Not executable: %s. Run: chmod +x %s\n' "$appimage" "$appimage" >&2
    exit 1
}

[[ -f $repo_desktop ]] || {
    printf 'Missing %s; this checkout is incomplete.\n' "$repo_desktop" >&2
    exit 1
}

if dpkg-query -W -f='${Status}' libfuse2t64 2>/dev/null | grep -q '^install ok installed$'; then
    printf '%s\n' 'libfuse2t64 already installed; skipping apt-get install.'
else
    sudo apt-get update
    sudo apt-get install -y libfuse2t64
fi

mkdir -p "$(dirname "$autostart_desktop")"
cat >"$autostart_desktop" <<AUTOSTART
[Desktop Entry]
Type=Application
Name=BB
Comment=Agent development environment
Exec=$appimage
Terminal=false
X-GNOME-Autostart-enabled=true
AUTOSTART
printf 'Autostart entry written: %s\n' "$autostart_desktop"

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

printf '%s\n' 'bb-server applied.'
