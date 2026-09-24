#!/usr/bin/env bash
# Shared argument and verification helpers for credential modules. Source; do not execute directly.

cred_target=''
cred_confirmed=0
cred_failures=0

cred_parse_target() {
    cred_target=''
    cred_confirmed=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --target)
                [[ $# -ge 2 && -z $cred_target ]] || {
                    printf '%s\n' 'Use --target exactly once.' >&2
                    return 2
                }
                cred_target="$2"
                shift 2
                ;;
            --confirmed)
                ((cred_confirmed == 0)) || {
                    printf '%s\n' 'Use --confirmed at most once.' >&2
                    return 2
                }
                cred_confirmed=1
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

cred_handle_parse_result() {
    local -r status="$1"
    local -r usage_function="$2"
    ((status == 0)) && return 0
    "$usage_function" >&2
    ((status == 10)) && return 10
    return "$status"
}

cred_require_target() {
    local target
    for target in "$@"; do
        [[ $cred_target == "$target" ]] && return 0
    done
    printf 'Target %q is not supported by this module.\n' "$cred_target" >&2
    return 2
}

cred_require_user() {
    [[ $EUID -ne 0 ]] && return 0
    printf '%s\n' 'Run as the normal desktop user, not with sudo.' >&2
    return 1
}

cred_repo_root() {
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd
}

cred_check() {
    local -r label="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        printf 'ok - %s\n' "$label"
    else
        printf 'not ok - %s\n' "$label" >&2
        cred_failures=$((cred_failures + 1))
    fi
}

cred_require_confirmation() {
    local -r label="$1"
    if ((cred_confirmed == 1)); then
        printf 'ok - %s (operator confirmed)\n' "$label"
    else
        printf 'not ok - %s (rerun with --confirmed after checking it)\n' "$label" >&2
        cred_failures=$((cred_failures + 1))
    fi
}

cred_finish_verify() {
    local -r module="$1"
    if ((cred_failures > 0)); then
        printf '%s verify failed for %s: %d check(s)\n' "$module" "$cred_target" "$cred_failures" >&2
        return 1
    fi
    printf '%s verify passed for %s\n' "$module" "$cred_target"
}
