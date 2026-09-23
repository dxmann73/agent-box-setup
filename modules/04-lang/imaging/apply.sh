#!/usr/bin/env bash
set -Eeuo pipefail
trap 'printf "ERROR: imaging apply failed at line %s\n" "$LINENO" >&2' ERR
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

usage() { printf '%s\n' 'Usage: sudo ./apply.sh --target daily-host'; }
if lang_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
lang_handle_parse_result "$status" usage || exit "$?"
lang_require_target || { usage >&2; exit 2; }
[[ "$lang_target" == daily-host ]] || {
    printf '%s\n' 'imaging is catalog-ticked only on daily hosts; use --target daily-host.' >&2
    exit 2
}
lang_require_sudo_user

setup_user="$SUDO_USER"
setup_home="$(getent passwd "$setup_user" | awk -F: 'NR == 1 { print $6 }')"
[[ -n "$setup_home" && -d "$setup_home" ]] || {
    printf 'Could not resolve a home directory for %s.\n' "$setup_user" >&2
    exit 1
}
lang_install_packages imagemagick ffmpeg inkscape graphicsmagick pngquant optipng libimage-exiftool-perl \
    python3-pil
sudo -u "$setup_user" env HOME="$setup_home" npm prefix -g | grep -qx "$setup_home/.npm-global" || {
    printf '%s\n' 'npm global prefix is not ~/.npm-global. Apply node-24 first.' >&2
    exit 1
}
sudo -u "$setup_user" env HOME="$setup_home" npm install -g sharp sharp-cli @resvg/resvg-js
printf 'imaging applied for %s.\n' "$lang_target"
