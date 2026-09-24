#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "ERROR: losslesscut update failed at line %s\n" "$LINENO" >&2' ERR

readonly appimage="$HOME/Applications/LosslessCut.AppImage"
readonly asset_name='LosslessCut-linux-x86_64.AppImage'
readonly release_api='https://api.github.com/repos/mifi/lossless-cut/releases/latest'

usage() {
    cat <<'USAGE'
Usage: ./update.sh

Installs or updates ~/Applications/LosslessCut.AppImage from the latest GitHub release. Compares the
local file's SHA-256 with the release asset digest and downloads only when they differ. The new file
is verified against that digest before it replaces the old one.

LosslessCut has no built-in updater; apply.sh and ~/update-tools.sh both call this script.

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
    printf '%s\n' 'Run as the normal user; the AppImage lives under $HOME.' >&2
    exit 1
}

for cmd in curl jq sha256sum; do
    command -v "$cmd" >/dev/null 2>&1 || {
        printf 'Missing required command: %s\n' "$cmd" >&2
        exit 1
    }
done

release_json=$(curl --fail --location --silent --show-error --max-time 30 "$release_api")
tag=$(jq -er '.tag_name' <<<"$release_json")

asset_json=$(jq -ec --arg name "$asset_name" '.assets[] | select(.name == $name)' <<<"$release_json") || {
    printf 'Release %s has no asset %s; the upstream asset naming changed.\n' "$tag" "$asset_name" >&2
    exit 1
}

download_url=$(jq -er '.browser_download_url' <<<"$asset_json")
digest=$(jq -er '.digest | strings | select(startswith("sha256:"))' <<<"$asset_json") || {
    printf 'Release %s asset %s has no sha256 digest; refusing an unverified download.\n' \
        "$tag" "$asset_name" >&2
    exit 1
}
readonly expected_sha="${digest#sha256:}"

if [[ -f $appimage ]]; then
    current_sha=$(sha256sum "$appimage" | cut -d ' ' -f 1)
    if [[ $current_sha == "$expected_sha" ]]; then
        printf 'LosslessCut AppImage already at %s: %s\n' "$tag" "$appimage"
        exit 0
    fi
fi

mkdir -p "$(dirname "$appimage")"

# Same directory as the target so the final mv is an atomic rename. A running LosslessCut keeps its
# already-mounted old file.
tmp_file=$(mktemp "$appimage.XXXXXX")
trap 'rm -f "$tmp_file"' EXIT

printf 'Downloading LosslessCut %s\n' "$tag"
curl --fail --location --silent --show-error --max-time 900 --output "$tmp_file" "$download_url"

downloaded_sha=$(sha256sum "$tmp_file" | cut -d ' ' -f 1)
[[ $downloaded_sha == "$expected_sha" ]] || {
    printf 'Checksum mismatch for %s: expected %s, got %s\n' "$download_url" "$expected_sha" \
        "$downloaded_sha" >&2
    exit 1
}

chmod 0755 "$tmp_file"
mv -f "$tmp_file" "$appimage"
printf 'LosslessCut AppImage updated to %s: %s\n' "$tag" "$appimage"
