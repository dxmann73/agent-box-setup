#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "ERROR: markdownlint apply failed at line %s\n" "$LINENO" >&2' ERR

usage() {
    cat <<'USAGE'
Usage: ./apply.sh

Installs markdownlint-cli globally via npm and symlinks the shared
.markdownlint.json from the repo into ~/projects/.markdownlint.json. Any
pre-existing regular file at the symlink target is moved into
~/.agent-box-setup-backup/ before the symlink is created.

Requires node-24 (npm on PATH, user-level ~/.npm-global prefix).

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
    printf '%s\n' 'Run as the normal user; this module writes only under $HOME.' >&2
    exit 1
}

command -v npm >/dev/null 2>&1 || {
    printf '%s\n' 'npm not found on PATH. Apply node-24 first.' >&2
    exit 1
}

npm_prefix="$(npm prefix -g)"
case "$npm_prefix" in
    "$HOME"/*)
        ;;
    *)
        printf 'npm global prefix is %s, expected a path under %s. Fix node-24 first.\n' \
            "$npm_prefix" "$HOME" >&2
        exit 1
        ;;
esac

module_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "$module_dir/../../.." && pwd)"
src_file="$repo_dir/.markdownlint.json"
dst_file="$HOME/projects/.markdownlint.json"
backup_dir="$HOME/.agent-box-setup-backup"

[[ -f "$src_file" ]] || {
    printf 'Payload missing: %s not found.\n' "$src_file" >&2
    exit 1
}

npm install -g markdownlint-cli

mkdir -p "$HOME/projects"

if [[ -L "$dst_file" ]]; then
    ln -sfn "$src_file" "$dst_file"
elif [[ -e "$dst_file" ]]; then
    mkdir -p "$backup_dir"
    mv "$dst_file" "$backup_dir/"
    ln -s "$src_file" "$dst_file"
else
    ln -s "$src_file" "$dst_file"
fi

printf '%s\n' 'markdownlint applied.'
