#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh

Run inside the browser guest. Checks Google Chrome package state and unattended
upgrade policy for the Chrome apt origin.

Environment:
  CHROME_VM_EXPECTED_HOSTNAME  Expected guest hostname. Default: chrome-vm

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

readonly expected_hostname="${CHROME_VM_EXPECTED_HOSTNAME:-chrome-vm}"
readonly chrome_keyring=/usr/share/keyrings/google-chrome.gpg
readonly chrome_list=/etc/apt/sources.list.d/google-chrome.list
readonly unattended_google=/etc/apt/apt.conf.d/51unattended-upgrades-google-chrome

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

expected_hostname_matches() {
    [[ "$(hostname)" == "$expected_hostname" ]]
}

dpkg_package_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -qx 'install ok installed'
}

chrome_source_list_present() {
    [[ -r "$chrome_list" ]] || return 1
    grep -Fxq \
        "deb [arch=amd64 signed-by=${chrome_keyring}] https://dl.google.com/linux/chrome/deb/ stable main" \
        "$chrome_list"
}

chrome_keyring_present() {
    [[ -r "$chrome_keyring" ]] || return 1
    [[ "$(stat -c '%a' "$chrome_keyring")" == 644 ]]
}

google_unattended_origin_present() {
    [[ -r "$unattended_google" ]] || return 1
    grep -Fxq '        "origin=Google LLC,codename=stable";' "$unattended_google"
}

apt_periodic_enabled() {
    grep -Fxq 'APT::Periodic::Update-Package-Lists "1";' \
        /etc/apt/apt.conf.d/20auto-upgrades || return 1
    grep -Fxq 'APT::Periodic::Unattended-Upgrade "1";' \
        /etc/apt/apt.conf.d/20auto-upgrades
}

system_unit_enabled() {
    systemctl is-enabled --quiet "$1"
}

check 'inside a virtualized guest' inside_guest
check 'expected browser guest hostname' expected_hostname_matches
check 'dpkg-query available' command_available dpkg-query
check 'grep available' command_available grep
check 'stat available' command_available stat
check 'systemctl available' command_available systemctl
check 'google-chrome-stable package installed' dpkg_package_installed google-chrome-stable
check 'google-chrome-stable command available' command_available google-chrome-stable
check 'Google Chrome apt keyring present' chrome_keyring_present
check 'Google Chrome apt source present' chrome_source_list_present
check 'unattended-upgrades package installed' dpkg_package_installed unattended-upgrades
check 'Chrome unattended-upgrades origin present' google_unattended_origin_present
check 'apt periodic upgrades enabled' apt_periodic_enabled
check 'apt-daily.timer enabled' system_unit_enabled apt-daily.timer
check 'apt-daily-upgrade.timer enabled' system_unit_enabled apt-daily-upgrade.timer

if ((failures > 0)); then
    printf 'chrome-vm-packages verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'chrome-vm-packages verify passed'
