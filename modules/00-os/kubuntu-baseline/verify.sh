#!/usr/bin/env bash
set -Eeuo pipefail

target=""
failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh --target daily-host|guest

Options:
  --target VALUE   daily-host or guest
  -h, --help       Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target)
            target="${2:-}"
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

if [[ -z "$target" ]]; then
    if systemd-detect-virt --quiet 2>/dev/null; then
        target="guest"
    else
        target="daily-host"
    fi
fi

case "$target" in
    daily-host | guest) ;;
    *)
        printf 'Invalid target: %s\n' "$target" >&2
        usage >&2
        exit 2
        ;;
esac

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

package_installed() {
    local -r package="$1"

    dpkg-query -W -f='${Status}\n' "$package" 2>/dev/null | grep -qx 'install ok installed'
}

locale_generated() {
    local -r locale_name="${KUBUNTU_BASELINE_EXPECT_LOCALE:-en_US.UTF-8}"

    locale -a | grep -Eiq "^${locale_name/./[.]}$|^${locale_name/UTF-8/utf8}$"
}

auto_upgrades_enabled() {
    grep -q '^APT::Periodic::Update-Package-Lists "1";' /etc/apt/apt.conf.d/20auto-upgrades &&
        grep -q '^APT::Periodic::Unattended-Upgrade "1";' /etc/apt/apt.conf.d/20auto-upgrades
}

needrestart_auto() {
    grep -q '^\$nrconf{restart} = '\''a'\'';' /etc/needrestart/conf.d/50local.conf &&
        grep -q '^\$nrconf{kernelhints} = 0;' /etc/needrestart/conf.d/50local.conf
}

automatic_reboot_policy() {
    grep -q '^Unattended-Upgrade::Automatic-Reboot "false";' /etc/apt/apt.conf.d/52unattended-upgrades-local &&
        ! grep -q '^Unattended-Upgrade::Automatic-Reboot-Time' /etc/apt/apt.conf.d/52unattended-upgrades-local
}

reboot_notification_path_enabled() {
    systemctl --user is-enabled --quiet agent-box-reboot-required.path
}

release_prompt_lts() {
    [[ ! -f /etc/update-manager/release-upgrades ]] ||
        grep -qx 'Prompt=lts' /etc/update-manager/release-upgrades
}

host_dirs_exist() {
    [[ -d "$HOME/projects" && -d "$HOME/vms" && -d "$HOME/backup/vm" ]]
}

system_info_dir_exists() {
    [[ -d "$HOME/system-info" ]]
}

screen_lock_value_is() {
    local -r key="$1"
    local -r expected="$2"

    [[ "$(kreadconfig6 --file kscreenlockerrc --group Daemon --key "$key")" == "$expected" ]]
}

host_autologin_disabled() {
    ! grep -Rqs '^User=[^[:space:]]' /etc/sddm.conf.d
}

guest_autologin_enabled() {
    grep -qx "User=$USER" /etc/sddm.conf.d/99-autologin.conf &&
        grep -qx 'Session=plasma' /etc/sddm.conf.d/99-autologin.conf
}

guest_sudo_passwordless() {
    sudo -n true
}

host_sudo_protected() {
    [[ ! -e /etc/sudoers.d/agent-nopasswd ]]
}

for package in ca-certificates curl git locales python3 unattended-upgrades needrestart kwallet6; do
    check "package installed: $package" package_installed "$package"
done

check 'locale generated' locale_generated
check 'unattended upgrades periodic config enabled' auto_upgrades_enabled
check 'apt daily timers enabled' systemctl is-enabled --quiet apt-daily.timer
check 'apt daily upgrade timer enabled' systemctl is-enabled --quiet apt-daily-upgrade.timer
check 'needrestart restarts services automatically' needrestart_auto
check 'automatic reboot disabled' automatic_reboot_policy
check 'reboot-required notification watcher enabled' reboot_notification_path_enabled
check 'release upgrades prompt for LTS' release_prompt_lts
check '~/system-info directory exists' system_info_dir_exists

if [[ "$target" == "daily-host" ]]; then
    check 'host layout directories exist' host_dirs_exist
    check 'host autologin disabled' host_autologin_disabled
    check 'host screen autolock disabled' screen_lock_value_is Autolock false
    check 'host locks on resume' screen_lock_value_is LockOnResume true
    check 'host has no agent NOPASSWD sudoers file' host_sudo_protected
else
    check 'guest autologin enabled' guest_autologin_enabled
    check 'guest screen autolock disabled' screen_lock_value_is Autolock false
    check 'guest lock on resume disabled' screen_lock_value_is LockOnResume false
    check 'guest passwordless sudo works' guest_sudo_passwordless
fi

if ((failures > 0)); then
    printf 'kubuntu-baseline verify failed for %s: %d check(s)\n' "$target" "$failures" >&2
    exit 1
fi

printf 'kubuntu-baseline verify passed for %s\n' "$target"
