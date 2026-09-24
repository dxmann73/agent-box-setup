#!/usr/bin/env bash
set -Eeuo pipefail

trap 'printf "ERROR: dropbox-client apply failed at line %s\n" "$LINENO" >&2' ERR
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

package_file=''

usage() {
    cat <<'USAGE'
Usage: ./apply.sh --package /absolute/path/to/dropbox.deb

Installs the official Dropbox Ubuntu package already downloaded by the desktop user. The package is
not fetched by this script so that the current vendor-provided package is reviewed before install.
USAGE
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --package)
            shift
            [[ $# -gt 0 ]] || app_die 'Missing path after --package.'
            package_file="$1"
            ;;
        -h | --help) usage; exit 0 ;;
        *) app_die "Unknown argument: $1" ;;
    esac
    shift
done

app_require_normal_user
[[ -n $package_file ]] || { usage >&2; exit 2; }
[[ $package_file = /* ]] || app_die '--package must be an absolute path.'
[[ -f $package_file ]] || app_die "Package not found: $package_file"
[[ $(dpkg-deb --field "$package_file" Package) == dropbox ]] ||
    app_die "Package is not Dropbox: $package_file"

sudo apt-get update
sudo apt-get install -y "$package_file"
printf '%s\n' 'dropbox-client applied. Start Dropbox and complete its interactive sign-in.'
