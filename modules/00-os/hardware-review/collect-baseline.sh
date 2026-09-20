#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "ERROR: hardware-review baseline collection failed at line %s\n" "$LINENO" >&2' ERR

output_dir="${HARDWARE_REVIEW_OUTPUT_DIR:-$HOME/system-info}"

usage() {
    cat <<'USAGE'
Usage: ./collect-baseline.sh [--output-dir DIR]

Options:
  --output-dir DIR   Baseline output directory (default: ~/system-info)
  -h, --help         Show this help
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output-dir)
            output_dir="${2:-}"
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

[[ -n "$output_dir" ]] || {
    printf '%s\n' 'Missing --output-dir value.' >&2
    exit 2
}

package_installed() {
    local -r package="$1"

    dpkg-query -W -f='${Status}\n' "$package" 2>/dev/null | grep -qx 'install ok installed'
}

ensure_packages() {
    local -a missing=()
    local package

    for package in mesa-utils mesa-vulkan-drivers pciutils vulkan-tools; do
        if ! package_installed "$package"; then
            missing+=("$package")
        fi
    done

    if ((${#missing[@]} > 0)); then
        sudo apt-get update
        sudo apt-get install -y "${missing[@]}"
    fi
}

write_command_output() {
    local -r destination="$1"
    shift

    printf '## %s\n\n' "$*" >"$destination"
    "$@" >>"$destination"
}

ensure_packages
mkdir -p "$output_dir"

write_command_output "$output_dir/gpu-pci.txt" lspci -k
write_command_output "$output_dir/vulkan.txt" vulkaninfo --summary
write_command_output "$output_dir/mesa.txt" glxinfo -B

if command -v powerprofilesctl >/dev/null 2>&1; then
    write_command_output "$output_dir/powerprofiles.txt" powerprofilesctl list
fi

printf 'hardware-review baselines written to %s\n' "$output_dir"
