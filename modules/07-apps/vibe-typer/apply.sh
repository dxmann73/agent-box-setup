#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "ERROR: vibe-typer apply failed at line %s\n" "$LINENO" >&2' ERR
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

overlay_dir=''

usage() {
    cat <<'USAGE'
Usage: ./apply.sh --overlay /absolute/path/to/identity

Wires the reviewed, manually downloaded VibeTyper AppImage to deployment-owned launcher, desktop,
and update-reminder files. The AppImage itself is never downloaded or replaced by this script.
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --overlay)
            shift
            [[ $# -gt 0 ]] || app_die 'Missing path after --overlay.'
            overlay_dir="$1"
            ;;
        -h | --help) usage; exit 0 ;;
        *) app_die "Unknown argument: $1" ;;
    esac
    shift
done

app_require_normal_user
[[ -n $overlay_dir ]] || { usage >&2; exit 2; }
[[ $overlay_dir = /* ]] || app_die '--overlay must be an absolute path.'
[[ -x $HOME/Applications/VibeTyper.AppImage ]] ||
    app_die 'VibeTyper AppImage is missing or not executable; download and review it first.'

link_overlay_file() {
    local -r source="$1"
    local -r target="$2"

    [[ -f $source ]] || app_die "Overlay file is missing: $source"
    mkdir -p "$(dirname "$target")"
    if [[ -L $target ]] && [[ $(readlink -f -- "$target") == "$(readlink -f -- "$source")" ]]; then
        return
    fi
    [[ ! -e $target && ! -L $target ]] || app_die "Refusing to replace existing file: $target"
    ln -s "$source" "$target"
}

link_overlay_file "$overlay_dir/vibe-typer-launch.sh" "$HOME/.local/bin/vibe-typer-launch.sh"
link_overlay_file "$overlay_dir/vibe-typer-update-reminder.sh" \
    "$HOME/.local/bin/vibe-typer-update-reminder.sh"
link_overlay_file "$overlay_dir/applications/vibe-typer.desktop" \
    "$HOME/.local/share/applications/vibe-typer.desktop"
link_overlay_file "$overlay_dir/systemd/vibe-typer-update-reminder.service" \
    "$HOME/.config/systemd/user/vibe-typer-update-reminder.service"
link_overlay_file "$overlay_dir/systemd/vibe-typer-update-reminder.timer" \
    "$HOME/.config/systemd/user/vibe-typer-update-reminder.timer"

systemctl --user daemon-reload
systemctl --user enable --now vibe-typer-update-reminder.timer

if app_command_available update-desktop-database; then
    update-desktop-database "$HOME/.local/share/applications"
fi
if app_command_available kbuildsycoca6; then
    kbuildsycoca6 >/dev/null 2>&1 || true
fi

printf '%s\n' 'vibe-typer applied.'
