#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "ERROR: claude-code-bootstrap apply failed at line %s\n" "$LINENO" >&2' ERR

usage() {
    cat <<'USAGE'
Usage: ./apply.sh

Installs Claude Code (`claude`) via the official installer.
Idempotent: skips the installer when `claude` is already on PATH.

Kubuntu Desktop ships `curl` and `ca-certificates` by default; verify.sh asserts them.
This module does not install `git`; that happens by hand in START-HERE.md §2 alongside the repo clones.

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

[[ $EUID -ne 0 ]] || {
    printf '%s\n' 'Run as the normal user; the installer writes under $HOME.' >&2
    exit 1
}

if command -v claude >/dev/null 2>&1; then
    printf '%s\n' 'claude already on PATH; skipping installer.'
else
    curl -fsSL https://claude.ai/install.sh | bash
fi

if ! command -v claude >/dev/null 2>&1; then
    printf '%s\n' \
        'claude is still not on PATH after install.' \
        'The installer places it under ~/.local/bin; ensure that directory is on PATH,' \
        'then rerun.' >&2
    exit 1
fi

printf '%s\n' 'claude-code-bootstrap applied. Sign in with `claude` (claude-login) when ready.'
