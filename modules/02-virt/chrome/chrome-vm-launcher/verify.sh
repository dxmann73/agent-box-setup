#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh

Checks the host-side Chrome VM launcher and confirms it is not the default URL handler.

Optional environment:
  CHROME_VM_LAUNCHER_HOST_BROWSER_DESKTOP
      Expected host default browser desktop file. When unset, verify.sh only checks that
      chrome-vm.desktop is not registered as the http(s) or text/html default.

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
    shift
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

bare_metal_host() {
    ! systemd-detect-virt --quiet
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly launcher_source="${script_dir}/show-chrome-vm.sh"
readonly desktop_source="${script_dir}/chrome-vm.desktop"
readonly icon_source="${script_dir}/google-chrome-vm.png"
readonly installed_launcher="$HOME/.local/bin/show-chrome-vm.sh"
readonly installed_desktop="$HOME/.local/share/applications/chrome-vm.desktop"
readonly installed_icon="$HOME/.local/share/icons/hicolor/256x256/apps/google-chrome-vm.png"

symlink_targets_source() {
    local -r link_path="$1"
    local -r expected="$2"

    [[ -L "$link_path" ]] || return 1
    [[ "$(readlink -f -- "$link_path")" == "$(readlink -f -- "$expected")" ]]
}

launcher_installed() {
    symlink_targets_source "$installed_launcher" "$launcher_source" || return 1
    [[ -x "$installed_launcher" ]]
}

desktop_installed() {
    symlink_targets_source "$installed_desktop" "$desktop_source" || return 1
    grep -qx 'Exec=show-chrome-vm.sh' "$installed_desktop" || return 1
    grep -qx 'StartupWMClass=virt-viewer' "$installed_desktop" || return 1
    grep -qx 'Icon=google-chrome-vm' "$installed_desktop"
}

desktop_file_valid() {
    command -v desktop-file-validate >/dev/null 2>&1 || return 0
    desktop-file-validate "$installed_desktop"
}

launcher_rejects_urls() {
    local result

    set +e
    result="$("$installed_launcher" 'https://example.invalid/' 2>&1)"
    local -r status=$?
    set -e

    [[ $status -ne 0 ]] || return 1
    grep -Fq 'This launcher is not a URL handler.' <<<"$result"
}

default_for() {
    local -r mime_type="$1"

    if command -v xdg-mime >/dev/null 2>&1; then
        xdg-mime query default "$mime_type" 2>/dev/null || true
    fi
}

chrome_vm_not_default_handler() {
    local key

    for key in x-scheme-handler/http x-scheme-handler/https text/html; do
        [[ "$(default_for "$key")" != chrome-vm.desktop ]] || return 1
    done
}

expected_host_browser_is_default() {
    local key
    local current

    [[ -n "${CHROME_VM_LAUNCHER_HOST_BROWSER_DESKTOP:-}" ]] || return 0
    command -v xdg-mime >/dev/null 2>&1 || return 1

    for key in x-scheme-handler/http x-scheme-handler/https text/html; do
        current="$(xdg-mime query default "$key" 2>/dev/null || true)"
        [[ "$current" == "$CHROME_VM_LAUNCHER_HOST_BROWSER_DESKTOP" ]] || return 1
    done
}

check 'daily host, not guest' bare_metal_host
check 'show-chrome-vm.sh source executable' test -x "$launcher_source"
check 'chrome-vm.desktop source present' test -r "$desktop_source"
check 'launcher symlink installed' launcher_installed
check 'desktop entry symlink installed' desktop_installed
check 'Chrome icon symlink installed' symlink_targets_source "$installed_icon" "$icon_source"
check 'desktop entry validates when validator is installed' desktop_file_valid
check 'launcher rejects URL arguments' launcher_rejects_urls
check 'chrome-vm.desktop is not the default URL/html handler' chrome_vm_not_default_handler
check 'expected host browser remains default when configured' expected_host_browser_is_default

if ((failures > 0)); then
    printf 'chrome-vm-launcher verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'chrome-vm-launcher verify passed'
