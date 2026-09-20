#!/usr/bin/env bash
set -Eeuo pipefail

readonly repo_dir="$HOME/projects/agent-box-setup"
readonly expected_origin_re='^https://github\.com/dxmann73/agent-box-setup(\.git)?$'

failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh

Checks that git is installed and that ~/projects/agent-box-setup is a working checkout of the
dxmann73/agent-box-setup repository with the expected payload trees.

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

repo_is_git_checkout() {
    [[ -d "$repo_dir/.git" ]]
}

origin_matches() {
    local origin
    origin=$(git -C "$repo_dir" remote get-url origin 2>/dev/null) || return 1
    [[ $origin =~ $expected_origin_re ]]
}

path_exists() {
    [[ -e "$repo_dir/$1" ]]
}

check 'git on PATH' command_available git
check '~/projects/agent-box-setup is a git checkout' repo_is_git_checkout

if repo_is_git_checkout; then
    check 'origin remote points at dxmann73/agent-box-setup' origin_matches
    check 'agents/ payload present' path_exists agents
    check 'user-home/ payload present' path_exists user-home
    check 'modules/ payload present' path_exists modules
fi

if ((failures > 0)); then
    printf 'clone-agent-box-setup verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'clone-agent-box-setup verify passed'
