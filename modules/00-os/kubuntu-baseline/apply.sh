#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "ERROR: kubuntu-baseline apply failed at line %s\n" "$LINENO" >&2' ERR

target=""
backup_dir="/var/backups/agent-box-setup-kubuntu-baseline-$(date +%Y%m%d-%H%M%S)"
backup_created=0

usage() {
    cat <<'USAGE'
Usage: sudo ./apply.sh --target daily-host|guest

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

case "$target" in
    daily-host | guest) ;;
    "")
        printf '%s\n' 'Missing --target daily-host|guest.' >&2
        usage >&2
        exit 2
        ;;
    *)
        printf 'Invalid target: %s\n' "$target" >&2
        usage >&2
        exit 2
        ;;
esac

[[ $EUID -eq 0 && -n "${SUDO_USER:-}" && "$SUDO_USER" != root ]] || {
    printf '%s\n' 'Run with sudo from the normal desktop user account.' >&2
    exit 1
}

setup_user="$SUDO_USER"
setup_home="$(getent passwd "$setup_user" | awk -F: 'NR == 1 { print $6 }')"
[[ -n "$setup_home" && -d "$setup_home" ]] || {
    printf 'Could not resolve a home directory for %s.\n' "$setup_user" >&2
    exit 1
}
setup_group="$(id -gn "$setup_user")"
readonly target setup_user setup_home setup_group

create_backup_dir() {
    if [[ $backup_created -eq 0 ]]; then
        install -d -m 0700 "$backup_dir"
        backup_created=1
    fi
}

backup_path() {
    local -r path="$1"
    [[ -e "$path" ]] || return 0

    create_backup_dir
    cp -a --parents "$path" "$backup_dir"
}

write_file() {
    local -r destination="$1"
    local -r mode="$2"
    local temporary

    temporary="$(mktemp)"
    cat >"$temporary"
    if ! cmp -s "$temporary" "$destination" 2>/dev/null; then
        backup_path "$destination"
        install -D -m "$mode" "$temporary" "$destination"
    fi
    rm -f -- "$temporary"
}

remove_if_present() {
    local -r path="$1"
    [[ -e "$path" ]] || return 0

    backup_path "$path"
    rm -f -- "$path"
}

write_sudoers() {
    local -r destination="/etc/sudoers.d/agent-nopasswd"
    local temporary

    temporary="$(mktemp)"
    printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$setup_user" >"$temporary"
    visudo -cf "$temporary" >/dev/null
    if ! cmp -s "$temporary" "$destination" 2>/dev/null; then
        backup_path "$destination"
        install -D -m 0440 "$temporary" "$destination"
    fi
    rm -f -- "$temporary"
}

run_user() {
    sudo -u "$setup_user" env HOME="$setup_home" USER="$setup_user" "$@"
}

write_desktop_policy() {
    local -r mode="$1"

    if [[ "$mode" == "protected" ]]; then
        run_user kwriteconfig6 --file kscreenlockerrc --group Daemon --key Autolock false
        run_user kwriteconfig6 --file kscreenlockerrc --group Daemon --key LockOnResume true
        run_user kwriteconfig6 --file kscreenlockerrc --group Daemon --key Timeout 0
        remove_if_present /etc/sddm.conf.d/99-autologin.conf
    else
        run_user kwriteconfig6 --file powerdevilrc --group AC --group Display \
            --key DimDisplayWhenIdle false
        run_user kwriteconfig6 --file powerdevilrc --group AC --group Display \
            --key DimDisplayIdleTimeoutSec -- -1
        run_user kwriteconfig6 --file powerdevilrc --group AC --group Display \
            --key TurnOffDisplayWhenIdle false
        run_user kwriteconfig6 --file powerdevilrc --group AC --group Display \
            --key TurnOffDisplayIdleTimeoutSec -- -1
        run_user kwriteconfig6 --file kscreenlockerrc --group Daemon --key Autolock false
        run_user kwriteconfig6 --file kscreenlockerrc --group Daemon --key LockOnResume false
        run_user kwriteconfig6 --file kscreenlockerrc --group Daemon --key Timeout 0
        write_file /etc/sddm.conf.d/99-autologin.conf 0644 <<CONFIG
[Autologin]
User=$setup_user
Session=plasma
Relogin=false
CONFIG
    fi

    run_user kwriteconfig6 --file kwinrc --group ElectricBorders --key TopLeft None
    run_user kwriteconfig6 --file kwinrc --group Effect-overview --key BorderActivate ''
    run_user kwriteconfig6 --file kwinrc --group Effect-PresentWindows --key BorderActivate ''
    run_user kwriteconfig6 --file kwinrc --group Effect-PresentWindows --key BorderActivateAll ''
    run_user kwriteconfig6 --file kwinrc --group Effect-PresentWindows \
        --key BorderActivateClass ''
}

export DEBIAN_FRONTEND=noninteractive
readonly -a baseline_packages=(
    ca-certificates
    curl
    git
    gnupg
    ksshaskpass
    kwallet6
    kwalletmanager
    locales
    needrestart
    python3
    unattended-upgrades
)

apt-get update
apt-get install -y "${baseline_packages[@]}"

locale_list="${KUBUNTU_BASELINE_LOCALES:-en_US.UTF-8}"
for locale_name in $locale_list; do
    if ! grep -Eq "^[# ]*${locale_name}[[:space:]]+UTF-8" /etc/locale.gen; then
        printf '%s UTF-8\n' "$locale_name" >>/etc/locale.gen
    fi
    sed -i "s/^# *${locale_name}[[:space:]]\\+UTF-8/${locale_name} UTF-8/" /etc/locale.gen
done
locale-gen $locale_list
update-locale "LANG=${KUBUNTU_BASELINE_LANG:-en_US.UTF-8}"

write_file /etc/apt/apt.conf.d/20auto-upgrades 0644 <<'CONFIG'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
CONFIG

write_file /etc/apt/apt.conf.d/52unattended-upgrades-local 0644 <<'CONFIG'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}";
    "${distro_id}:${distro_codename}-security";
    "${distro_id}:${distro_codename}-updates";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Mail "";
CONFIG

write_file /etc/needrestart/conf.d/50local.conf 0644 <<'CONFIG'
$nrconf{restart} = 'a';
$nrconf{kernelhints} = 0;
CONFIG

if [[ -f /etc/update-manager/release-upgrades ]] &&
    ! grep -qx 'Prompt=lts' /etc/update-manager/release-upgrades; then
    backup_path /etc/update-manager/release-upgrades
    sed -i 's/^Prompt=.*/Prompt=lts/' /etc/update-manager/release-upgrades
fi

systemctl enable --now apt-daily.timer apt-daily-upgrade.timer
loginctl enable-linger "$setup_user"

install -d -o "$setup_user" -g "$setup_group" "$setup_home/system-info"

if [[ "$target" == "daily-host" ]]; then
    install -d -o "$setup_user" -g "$setup_group" \
        "$setup_home/projects" "$setup_home/vms" "$setup_home/backup/vm"
    remove_if_present /etc/sudoers.d/agent-nopasswd
    write_desktop_policy protected
else
    mkdir -p /etc/sddm.conf.d
    write_sudoers
    write_desktop_policy guest
fi

if [[ $backup_created -eq 1 ]]; then
    printf 'kubuntu-baseline applied for %s. Backups: %s\n' "$target" "$backup_dir"
else
    printf 'kubuntu-baseline applied for %s. No tracked files changed.\n' "$target"
fi
