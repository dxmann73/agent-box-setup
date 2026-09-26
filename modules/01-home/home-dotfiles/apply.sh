#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "ERROR: home-dotfiles apply failed at line %s\n" "$LINENO" >&2' ERR

usage() {
    cat <<'USAGE'
Usage: ./apply.sh

Symlinks the generic shell dotfiles and helper scripts from user-home/ into $HOME.
Any pre-existing regular file at the target is moved into ~/.agent-box-setup-backup/
before the symlink is created. Existing symlinks are refreshed (ln -sfn).

Does not touch:
  - ~/.bash_secrets                (login stage)
  - ~/projects/.markdownlint.json  (markdownlint module)
  - ~/.gitconfig                   (git-identity module)
  - wezterm/vscode/systemd/pi-launch/klipper payloads (own modules)

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

module_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd -- "$module_dir/../../.." && pwd)"
src_dir="$repo_dir/user-home"

[[ -f "$src_dir/.bashrc" ]] || {
    printf 'Payload missing: %s/.bashrc not found.\n' "$src_dir" >&2
    exit 1
}

backup_dir="$HOME/.agent-box-setup-backup"

link_one() {
    local -r src="$1"
    local -r dst="$2"

    if [[ -L "$dst" ]]; then
        ln -sfn "$src" "$dst"
        return
    fi

    if [[ -e "$dst" ]]; then
        mkdir -p "$backup_dir"
        mv "$dst" "$backup_dir/"
    fi

    ln -s "$src" "$dst"
}

link_one "$src_dir/.bashrc"          "$HOME/.bashrc"
link_one "$src_dir/.bash_aliases"    "$HOME/.bash_aliases"
link_one "$src_dir/.profile"         "$HOME/.profile"
link_one "$src_dir/ua.sh"            "$HOME/ua.sh"
link_one "$src_dir/update-tools.sh"  "$HOME/update-tools.sh"

printf '%s\n' 'home-dotfiles applied.'
