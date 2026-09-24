#!/usr/bin/env bash
# Compatibility entry point. The catalog runner owns verification behavior.
set -Eeuo pipefail

readonly repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
exec "$repo_dir/modules/verify-box.sh" "$@"
