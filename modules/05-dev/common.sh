#!/usr/bin/env bash

# Shared argument and environment guards for 05-dev module scripts.

dev_parse_target() {
    local -r usage="$1"
    shift

    if [[ $# -ne 2 || $1 != --target ]]; then
        printf '%s\n' "$usage" >&2
        exit 2
    fi

    DEV_TARGET="$2"
}

dev_require_target() {
    local target
    for target in "$@"; do
        [[ $DEV_TARGET == "$target" ]] && return 0
    done

    printf 'Target %q is not supported by this module.\n' "$DEV_TARGET" >&2
    exit 2
}

dev_require_user() {
    [[ $EUID -ne 0 ]] || {
        printf '%s\n' 'Run as the normal desktop user.' >&2
        exit 1
    }
}

dev_require_sudo_user() {
    [[ $EUID -eq 0 && -n ${SUDO_USER:-} && $SUDO_USER != root ]] || {
        printf '%s\n' 'Run with sudo from the normal desktop user.' >&2
        exit 1
    }
}

dev_repo_root() {
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd
}

dev_require_commands() {
    local command
    for command in "$@"; do
        command -v "$command" >/dev/null || {
            printf 'Required command unavailable: %s\n' "$command" >&2
            exit 1
        }
    done
}
