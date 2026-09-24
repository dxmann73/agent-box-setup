#!/usr/bin/env bash

# Shared helpers for independently runnable personal-app modules.

app_die() {
    printf '%s\n' "$*" >&2
    exit 1
}

app_require_root() {
    [[ $EUID -eq 0 ]] || app_die 'Run this script with sudo.'
}

app_require_normal_user() {
    [[ $EUID -ne 0 ]] || app_die 'Run this script as the desktop user, not root.'
}

app_package_installed() {
    dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -qx 'install ok installed'
}

app_snap_installed() {
    snap list "$1" >/dev/null 2>&1
}

app_command_available() {
    command -v "$1" >/dev/null 2>&1
}

app_check() {
    local -r label="$1"
    shift

    if "$@"; then
        printf 'ok - %s\n' "$label"
    else
        printf 'not ok - %s\n' "$label" >&2
        app_failures=$((app_failures + 1))
    fi
}

app_finish_verify() {
    local -r module="$1"

    if ((app_failures > 0)); then
        printf '%s verify failed: %d check(s)\n' "$module" "$app_failures" >&2
        exit 1
    fi

    printf '%s verify passed\n' "$module"
}
