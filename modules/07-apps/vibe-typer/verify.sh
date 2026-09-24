#!/usr/bin/env bash
set -Eeuo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
app_failures=0
overlay_dir=''

usage() {
    printf '%s\n' 'Usage: ./verify.sh --overlay /absolute/path/to/identity'
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

[[ -n $overlay_dir ]] || { usage >&2; exit 2; }
[[ $overlay_dir = /* ]] || app_die '--overlay must be an absolute path.'

symlink_targets() {
    local -r target="$1"
    local -r source="$2"

    [[ -L $target ]] && [[ $(readlink -f -- "$target") == "$(readlink -f -- "$source")" ]]
}

desktop_entry_valid() {
    if app_command_available desktop-file-validate; then
        desktop-file-validate "$HOME/.local/share/applications/vibe-typer.desktop"
    else
        [[ -f $HOME/.local/share/applications/vibe-typer.desktop ]]
    fi
}

app_check 'VibeTyper AppImage present and executable' test -x "$HOME/Applications/VibeTyper.AppImage"
app_check 'launcher symlink targets overlay' symlink_targets \
    "$HOME/.local/bin/vibe-typer-launch.sh" "$overlay_dir/vibe-typer-launch.sh"
app_check 'update-reminder symlink targets overlay' symlink_targets \
    "$HOME/.local/bin/vibe-typer-update-reminder.sh" "$overlay_dir/vibe-typer-update-reminder.sh"
app_check 'desktop-entry symlink targets overlay' symlink_targets \
    "$HOME/.local/share/applications/vibe-typer.desktop" "$overlay_dir/applications/vibe-typer.desktop"
app_check 'service symlink targets overlay' symlink_targets \
    "$HOME/.config/systemd/user/vibe-typer-update-reminder.service" \
    "$overlay_dir/systemd/vibe-typer-update-reminder.service"
app_check 'timer symlink targets overlay' symlink_targets \
    "$HOME/.config/systemd/user/vibe-typer-update-reminder.timer" \
    "$overlay_dir/systemd/vibe-typer-update-reminder.timer"
app_check 'desktop entry validates when validator is installed' desktop_entry_valid
app_check 'VibeTyper reminder timer enabled' \
    systemctl --user is-enabled --quiet vibe-typer-update-reminder.timer
app_finish_verify vibe-typer
