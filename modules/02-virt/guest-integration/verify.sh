#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh

Run inside the Kubuntu guest. Checks QEMU guest agent, SPICE integration, and the
Plasma Wayland clipboard bridge.

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

inside_guest() {
    systemd-detect-virt --vm --quiet
}

dpkg_package_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -qx 'install ok installed'
}

system_unit_enabled() {
    systemctl is-enabled --quiet "$1"
}

system_unit_active() {
    systemctl is-active --quiet "$1"
}

file_mode_is() {
    local -r path="$1"
    local -r expected="$2"

    [[ -e "$path" ]] || return 1
    [[ "$(stat -c '%a' "$path")" == "$expected" ]]
}

user_unit_file_present() {
    [[ -f /etc/systemd/user/spice-clipboard-sync.service ]] || return 1
    grep -qx 'ExecStart=/usr/local/libexec/spice-clipboard-watch' \
        /etc/systemd/user/spice-clipboard-sync.service
}

clipboard_helpers_present() {
    file_mode_is /usr/local/libexec/spice-clipboard-export 755 || return 1
    file_mode_is /usr/local/libexec/spice-clipboard-watch 755 || return 1
    grep -q 'wl-paste --list-types' /usr/local/libexec/spice-clipboard-export || return 1
    grep -q 'image/png' /usr/local/libexec/spice-clipboard-export || return 1
    grep -q 'clipboardHistoryUpdated' /usr/local/libexec/spice-clipboard-watch
}

user_service_enabled() {
    systemctl --user is-enabled --quiet spice-clipboard-sync.service
}

user_service_active_when_graphical() {
    if ! systemctl --user is-active --quiet graphical-session.target; then
        return 0
    fi
    systemctl --user is-active --quiet spice-clipboard-sync.service
}

legacy_text_bridge_disabled() {
    ! systemctl --user is-enabled --quiet klipper-clipboard-sync.service 2>/dev/null
}

klipper_images_enabled_when_config_exists() {
    local klipper_config="$HOME/.config/klipperrc"

    [[ ! -f "$klipper_config" ]] && return 0
    ! grep -Eq '^[[:space:]]*IgnoreImages[[:space:]]*=[[:space:]]*true[[:space:]]*$' \
        "$klipper_config"
}

check 'inside a virtualized guest' inside_guest
check 'dpkg-query available' command_available dpkg-query
check 'grep available' command_available grep
check 'stat available' command_available stat
check 'systemctl available' command_available systemctl
check 'qemu-guest-agent package installed' dpkg_package_installed qemu-guest-agent
check 'spice-vdagent package installed' dpkg_package_installed spice-vdagent
check 'dbus-bin package installed' dpkg_package_installed dbus-bin
check 'wl-clipboard package installed' dpkg_package_installed wl-clipboard
check 'xclip package installed' dpkg_package_installed xclip
check 'dbus-monitor available' command_available dbus-monitor
check 'qemu-guest-agent enabled' system_unit_enabled qemu-guest-agent
check 'qemu-guest-agent active' system_unit_active qemu-guest-agent
check 'spice-vdagentd enabled' system_unit_enabled spice-vdagentd
check 'spice-vdagentd active' system_unit_active spice-vdagentd
check 'clipboard helper scripts present' clipboard_helpers_present
check 'clipboard user unit present' user_unit_file_present
check 'clipboard user unit enabled' user_service_enabled
check 'clipboard user unit active when graphical session is active' user_service_active_when_graphical
check 'older text-only clipboard bridge disabled' legacy_text_bridge_disabled
check 'Klipper image history is not disabled when config exists' \
    klipper_images_enabled_when_config_exists

if ((failures > 0)); then
    printf '%s guest-integration check(s) failed\n' "$failures" >&2
    exit 1
fi

printf 'guest-integration verification passed\n'
