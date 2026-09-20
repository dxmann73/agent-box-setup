#!/usr/bin/env bash
set -Eeuo pipefail

baseline_dir="${HARDWARE_REVIEW_BASELINE_DIR:-$HOME/system-info}"
expected_gpu_driver="${HARDWARE_REVIEW_EXPECT_GPU_DRIVER:-amdgpu}"
expected_ram_gib="${HARDWARE_REVIEW_EXPECT_RAM_GIB:-}"
failures=0

usage() {
    cat <<'USAGE'
Usage: ./verify.sh

Environment:
  HARDWARE_REVIEW_BASELINE_DIR        Baseline directory (default: ~/system-info)
  HARDWARE_REVIEW_EXPECT_GPU_DRIVER  Expected display kernel driver (default: amdgpu)
  HARDWARE_REVIEW_EXPECT_RAM_GIB     Expected RAM in GiB, optional

Options:
  -h, --help                         Show this help
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

package_installed() {
    local -r package="$1"

    dpkg-query -W -f='${Status}\n' "$package" 2>/dev/null | grep -qx 'install ok installed'
}

command_available() {
    command -v "$1" >/dev/null 2>&1
}

has_display_gpu() {
    local pci_output

    pci_output="$(lspci -nn 2>/dev/null || true)"
    grep -Eiq 'VGA|3D|Display' <<<"$pci_output"
}

display_gpu_uses_expected_driver() {
    local pci_output

    pci_output="$(lspci -k 2>/dev/null || true)"
    awk -v expected="$expected_gpu_driver" '
        /VGA|3D|Display/ { in_display = 1; next }
        in_display && /Kernel driver in use:/ {
            if ($0 ~ expected) { found = 1 }
            in_display = 0
        }
        END { exit found ? 0 : 1 }
    ' <<<"$pci_output"
}

baseline_file_exists() {
    local -r name="$1"

    [[ -s "$baseline_dir/$name" ]]
}

current_vulkan_has_gpu() {
    vulkaninfo --summary 2>/dev/null | grep -Eiq 'GPU[0-9]|deviceName|driverName'
}

current_glx_has_renderer() {
    glxinfo -B 2>/dev/null | grep -Fq 'OpenGL renderer string:'
}

screen_lock_value_is() {
    local -r key="$1"
    local -r expected="$2"

    [[ "$(kreadconfig6 --file kscreenlockerrc --group Daemon --key "$key")" == "$expected" ]]
}

kwin_value_is() {
    local -r group="$1"
    local -r key="$2"
    local -r expected="$3"

    [[ "$(kreadconfig6 --file kwinrc --group "$group" --key "$key")" == "$expected" ]]
}

host_autologin_disabled() {
    ! grep -Rqs '^User=[^[:space:]]' /etc/sddm.conf.d
}

ram_matches_expected() {
    local actual_gib

    actual_gib="$(
        awk '/MemTotal:/ { printf "%.0f", $2 / 1024 / 1024 }' /proc/meminfo
    )"
    [[ "$actual_gib" == "$expected_ram_gib" ]]
}

check 'running on physical host' bash -c '! systemd-detect-virt --quiet'

for package in mesa-utils mesa-vulkan-drivers pciutils vulkan-tools; do
    check "package installed: $package" package_installed "$package"
done

for command_name in glxinfo lspci vulkaninfo; do
    check "command available: $command_name" command_available "$command_name"
done

check 'display GPU is present' has_display_gpu
check "display GPU uses ${expected_gpu_driver}" display_gpu_uses_expected_driver
check 'current Vulkan summary lists a GPU' current_vulkan_has_gpu
check 'current GLX summary lists a renderer' current_glx_has_renderer

check 'GPU PCI baseline saved' baseline_file_exists gpu-pci.txt
check 'Vulkan baseline saved' baseline_file_exists vulkan.txt
check 'Mesa baseline saved' baseline_file_exists mesa.txt

check 'host autologin disabled' host_autologin_disabled
check 'host screen autolock disabled' screen_lock_value_is Autolock false
check 'host locks on resume' screen_lock_value_is LockOnResume true
check 'host screen lock timeout disabled' screen_lock_value_is Timeout 0
check 'top-left screen edge disabled' kwin_value_is ElectricBorders TopLeft None
check 'overview edge activation disabled' kwin_value_is Effect-overview BorderActivate ''

if [[ -n "$expected_ram_gib" ]]; then
    check "RAM matches ${expected_ram_gib} GiB profile value" ram_matches_expected
fi

if ((failures > 0)); then
    printf 'hardware-review verify failed: %d check(s)\n' "$failures" >&2
    exit 1
fi

printf '%s\n' 'hardware-review verify passed'
