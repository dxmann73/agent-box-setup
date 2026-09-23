#!/usr/bin/env bash
# Shared functions for core-tool module scripts. Source; do not execute directly.

tool_target=""
tool_failures=0

tool_parse_target() {
    tool_target=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --target)
                [[ $# -ge 2 ]] || {
                    printf '%s\n' 'Missing value for --target.' >&2
                    return 2
                }
                tool_target="$2"
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

tool_parse_docker_target() {
    tool_smoke=0
    tool_target=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --target)
                [[ $# -ge 2 ]] || {
                    printf '%s\n' 'Missing value for --target.' >&2
                    return 2
                }
                tool_target="$2"
                shift 2
                ;;
            --smoke)
                tool_smoke=1
                shift
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

tool_handle_parse_result() {
    local -r status="$1"
    local -r usage_function="$2"

    ((status == 0)) && return 0
    "$usage_function" >&2
    ((status == 10)) && return 10
    return "$status"
}

tool_require_target() {
    case "$tool_target" in
        daily-host | agent-vm) ;;
        *)
            printf '%s\n' 'Use --target daily-host or agent-vm.' >&2
            return 2
            ;;
    esac
}

tool_require_agent_vm() {
    [[ "$tool_target" == agent-vm ]] && return 0
    printf '%s\n' 'Docker is catalog-ticked only on the agent VM; use --target agent-vm.' >&2
    return 2
}

tool_require_root() {
    [[ $EUID -eq 0 ]] && return 0
    printf '%s\n' 'Run with sudo.' >&2
    return 1
}

tool_require_sudo_user() {
    [[ $EUID -eq 0 && -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]] && return 0
    printf '%s\n' 'Run with sudo from the normal desktop user account.' >&2
    return 1
}

tool_install_package() {
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y "$1"
}

tool_package_installed() {
    dpkg-query -W -f='${Status}\n' "$1" 2>/dev/null | grep -qx 'install ok installed'
}

tool_check() {
    local -r label="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        printf 'ok - %s\n' "$label"
    else
        printf 'not ok - %s\n' "$label" >&2
        tool_failures=$((tool_failures + 1))
    fi
}

tool_finish_verify() {
    local -r module="$1"
    if ((tool_failures > 0)); then
        printf '%s verify failed for %s: %d check(s)\n' "$module" "$tool_target" "$tool_failures" >&2
        return 1
    fi
    printf '%s verify passed for %s\n' "$module" "$tool_target"
}
