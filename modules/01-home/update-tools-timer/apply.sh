#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "ERROR: update-tools-timer apply failed at line %s\n" "$LINENO" >&2' ERR

usage() {
    cat <<'USAGE'
Usage: ./apply.sh

Symlinks the update-tools user service and timer from user-home/systemd/ into
~/.config/systemd/user/, reloads the systemd user manager, and enables the
timer. The ~/update-tools.sh script symlink is owned by home-dotfiles and is
not created here.

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
src_dir="$repo_dir/user-home/systemd"
dst_dir="$HOME/.config/systemd/user"

for unit in update-tools.service update-tools.timer; do
    [[ -f "$src_dir/$unit" ]] || {
        printf 'Payload missing: %s/%s not found.\n' "$src_dir" "$unit" >&2
        exit 1
    }
done

[[ -x "$HOME/update-tools.sh" || -L "$HOME/update-tools.sh" ]] || {
    printf '~/update-tools.sh is missing. Run home-dotfiles apply first.\n' >&2
    exit 1
}

mkdir -p "$dst_dir"
ln -sfn "$src_dir/update-tools.service" "$dst_dir/update-tools.service"
ln -sfn "$src_dir/update-tools.timer"   "$dst_dir/update-tools.timer"

systemctl --user daemon-reload
systemctl --user enable --now update-tools.timer

printf '%s\n' 'update-tools-timer applied.'
