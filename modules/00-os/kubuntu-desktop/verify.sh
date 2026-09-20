#!/usr/bin/env bash
set -Eeuo pipefail

failures=0

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

package_installed() {
    local -r package="$1"

    dpkg-query -W -f='${Status}\n' "$package" 2>/dev/null | grep -qx 'install ok installed'
}

ubuntu_os() {
    # shellcheck disable=SC1091
    source /etc/os-release
    [[ "${ID:-}" == "ubuntu" ]]
}

kubuntu_desktop_installed() {
    package_installed kubuntu-desktop && package_installed plasma-desktop
}

sddm_installed() {
    package_installed sddm
}

hostname_is_sane() {
    local current_hostname
    current_hostname="$(hostname)"

    [[ -n "$current_hostname" && "$current_hostname" != "localhost" ]]
}

hostname_matches_expected() {
    [[ "$(hostname)" == "$KUBUNTU_DESKTOP_EXPECT_HOSTNAME" ]]
}

expected_user_exists() {
    getent passwd "$KUBUNTU_DESKTOP_EXPECT_USER" >/dev/null
}

check 'Ubuntu base OS is installed' ubuntu_os
check 'Kubuntu desktop packages are installed' kubuntu_desktop_installed
check 'SDDM display manager package is installed' sddm_installed
check 'hostname is set and not localhost' hostname_is_sane

if [[ -n "${KUBUNTU_DESKTOP_EXPECT_HOSTNAME:-}" ]]; then
    check "hostname matches ${KUBUNTU_DESKTOP_EXPECT_HOSTNAME}" hostname_matches_expected
fi

if [[ -n "${KUBUNTU_DESKTOP_EXPECT_USER:-}" ]]; then
    check "user exists: ${KUBUNTU_DESKTOP_EXPECT_USER}" expected_user_exists
fi

if ((failures > 0)); then
    printf 'kubuntu-desktop verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'kubuntu-desktop verify passed'
