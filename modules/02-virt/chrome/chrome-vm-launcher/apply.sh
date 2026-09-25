#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

trap 'printf "ERROR: chrome-vm-launcher apply failed at line %s\n" "$LINENO" >&2' ERR

usage() {
    cat <<'USAGE'
Usage: ./apply.sh

Installs the host-side launcher for the personal browser VM.

Optional environment:
  CHROME_VM_LAUNCHER_HOST_BROWSER_DESKTOP
      Desktop file to preserve as the host default browser, for example firefox_firefox.desktop.
      When unset, apply.sh leaves existing URL handlers alone.

Options:
  -h, --help   Show this help
USAGE
}

die() {
    printf '%s\n' "$@" >&2
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
    shift
done

[[ $EUID -ne 0 ]] || die 'Run as the desktop user, not as root.'

if systemd-detect-virt --quiet; then
    die "chrome-vm-launcher applies to daily hosts only. systemd-detect-virt reports $(systemd-detect-virt)."
fi

for binary in ln mkdir; do
    command -v "$binary" >/dev/null 2>&1 || die "Missing required command: ${binary}"
done

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
launcher_source="${script_dir}/show-chrome-vm.sh"
desktop_source="${script_dir}/chrome-vm.desktop"
icon_source="${script_dir}/google-chrome-vm.png"
icon_dir="$HOME/.local/share/icons/hicolor/256x256/apps"

[[ -x "$launcher_source" ]] || die "Missing executable launcher source: ${launcher_source}"
[[ -r "$desktop_source" ]] || die "Missing desktop entry source: ${desktop_source}"
[[ -r "$icon_source" ]] || die "Missing icon source: ${icon_source}"

mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications" "$icon_dir"

ln -sfn "$launcher_source" "$HOME/.local/bin/show-chrome-vm.sh"
ln -sfn "$desktop_source" "$HOME/.local/share/applications/chrome-vm.desktop"
ln -sfn "$icon_source" "${icon_dir}/google-chrome-vm.png"

if [[ -n "${CHROME_VM_LAUNCHER_HOST_BROWSER_DESKTOP:-}" ]]; then
    command -v kwriteconfig6 >/dev/null 2>&1 ||
        die 'kwriteconfig6 is required when CHROME_VM_LAUNCHER_HOST_BROWSER_DESKTOP is set.'

    for key in x-scheme-handler/http x-scheme-handler/https x-scheme-handler/webcal text/html; do
        kwriteconfig6 --file mimeapps.list --group 'Default Applications' \
            --key "$key" "$CHROME_VM_LAUNCHER_HOST_BROWSER_DESKTOP"
    done
    kwriteconfig6 --file kdeglobals --group General --key BrowserApplication \
        "$CHROME_VM_LAUNCHER_HOST_BROWSER_DESKTOP"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$HOME/.local/share/applications"
fi

if command -v kbuildsycoca6 >/dev/null 2>&1; then
    kbuildsycoca6 >/dev/null 2>&1 || true
fi

printf '%s\n' 'chrome-vm-launcher applied'
