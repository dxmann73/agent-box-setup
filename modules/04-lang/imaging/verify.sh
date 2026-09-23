#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

usage() { printf '%s\n' 'Usage: ./verify.sh --target daily-host'; }
if lang_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
lang_handle_parse_result "$status" usage || exit "$?"
lang_require_target || { usage >&2; exit 2; }
[[ "$lang_target" == daily-host ]] || {
    printf '%s\n' 'imaging is catalog-ticked only on daily hosts; use --target daily-host.' >&2
    exit 2
}
lang_require_user

imagemagick_available() { command -v magick || command -v convert; }
sharp_module_loads() { NODE_PATH="$(npm root -g)" node -e "require('sharp')"; }
resvg_module_loads() { NODE_PATH="$(npm root -g)" node -e "require('@resvg/resvg-js')"; }
for package in imagemagick ffmpeg inkscape graphicsmagick pngquant optipng libimage-exiftool-perl python3-pil; do
    lang_check "$package package installed" lang_package_installed "$package"
done
lang_check 'ImageMagick is on PATH' imagemagick_available
lang_check 'sharp is on PATH' command -v sharp
lang_check 'sharp module loads' sharp_module_loads
lang_check 'resvg module loads' resvg_module_loads
for binary in ffmpeg inkscape gm pngquant optipng exiftool python3; do
    lang_check "$binary is on PATH" command -v "$binary"
done
lang_check 'Pillow imports' python3 -c 'from PIL import Image'
lang_finish_verify imaging
