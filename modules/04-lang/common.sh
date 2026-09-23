#!/usr/bin/env bash
# Shared functions for language and JS CLI module scripts. Source; do not execute directly.

lang_target=""
lang_failures=0

lang_parse_target() {
    lang_target=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --target)
                [[ $# -ge 2 ]] || {
                    printf '%s\n' 'Missing value for --target.' >&2
                    return 2
                }
                lang_target="$2"
                shift 2
                ;;
            -h | --help)
                return 10
                ;;
            *)
                printf 'Unknown argument: %s\n' "$1" >&2
                return 2
                ;;
        esac
    done
}

lang_handle_parse_result() {
    local -r status="$1"
    local -r usage_function="$2"

    ((status == 0)) && return 0
    "$usage_function" >&2
    ((status == 10)) && return 10
    return "$status"
}

lang_require_target() {
    case "$lang_target" in
        daily-host | agent-vm) ;;
        *)
            printf '%s\n' 'Use --target daily-host or agent-vm.' >&2
            return 2
            ;;
    esac
}

lang_require_agent_vm() {
    [[ "$lang_target" == agent-vm ]] && return 0
    printf '%s\n' 'This module is catalog-ticked only on the agent VM; use --target agent-vm.' >&2
    return 2
}

lang_require_root() {
    [[ $EUID -eq 0 ]] && return 0
    printf '%s\n' 'Run with sudo.' >&2
    return 1
}

lang_require_sudo_user() {
    [[ $EUID -eq 0 && -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]] && return 0
    printf '%s\n' 'Run with sudo from the normal desktop user account.' >&2
    return 1
}

lang_require_user() {
    [[ $EUID -ne 0 ]] && return 0
    printf '%s\n' 'Run as the normal desktop user, not with sudo.' >&2
    return 1
}

lang_install_packages() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y "$@"
}

lang_package_installed() {
    dpkg-query -W -f='${Status}\n' "$1" 2>/dev/null | grep -qx 'install ok installed'
}

lang_npm_prefix_is_user_owned() {
    local prefix
    prefix="$(npm prefix -g)" || return 1
    [[ "$prefix" == "$HOME"/* ]]
}

lang_check() {
    local -r label="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        printf 'ok - %s\n' "$label"
    else
        printf 'not ok - %s\n' "$label" >&2
        lang_failures=$((lang_failures + 1))
    fi
}

lang_finish_verify() {
    local -r module="$1"
    if ((lang_failures > 0)); then
        printf '%s verify failed for %s: %d check(s)\n' "$module" "$lang_target" "$lang_failures" >&2
        return 1
    fi
    printf '%s verify passed for %s\n' "$module" "$lang_target"
}
