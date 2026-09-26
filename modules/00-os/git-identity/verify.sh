#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C

target=""
failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh --target daily-host|agent-vm

Checks the local ~/.gitconfig: a regular file (not a symlink), identity set,
nano as the editor, and a GitHub credential helper.

Options:
  --target VALUE   daily-host or agent-vm
  -h, --help       Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            [[ $# -ge 2 ]] || {
                printf '%s\n' 'Missing value for --target.' >&2
                exit 2
            }
            target="$2"
            shift 2
            ;;
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

case "$target" in
    daily-host | agent-vm) ;;
    *)
        printf '%s\n' 'Use --target daily-host or agent-vm.' >&2
        usage >&2
        exit 2
        ;;
esac

gitconfig="$HOME/.gitconfig"

check() {
    local -r label="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        printf 'ok - %s\n' "$label"
    else
        printf 'not ok - %s\n' "$label" >&2
        failures=$((failures + 1))
    fi
}

not_a_symlink() {
    [[ ! -L "$gitconfig" ]]
}

config_equals() {
    local -r key="$1"
    local -r expected="$2"
    [[ "$(git config --file "$gitconfig" --get "$key" 2>/dev/null)" == "$expected" ]]
}

github_helper_set() {
    git config --file "$gitconfig" --get-all 'credential.https://github.com.helper' \
        | grep -q 'gh auth git-credential'
}

check '~/.gitconfig exists as a regular file' test -f "$gitconfig"
check '~/.gitconfig is not a symlink' not_a_symlink
check 'user.name is set' git config --file "$gitconfig" --get user.name
check 'user.email is set' git config --file "$gitconfig" --get user.email
check 'core.editor is nano' config_equals core.editor nano
check 'GitHub credential helper is gh' github_helper_set
check 'git resolves an identity for this user' git config --get user.email

if ((failures > 0)); then
    printf 'git-identity verify failed for %s: %d check(s)\n' "$target" "$failures" >&2
    exit 1
fi

printf 'git-identity verify passed for %s\n' "$target"
