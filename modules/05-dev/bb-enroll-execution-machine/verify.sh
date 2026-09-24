#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
dev_parse_target 'Usage: ./verify.sh --target agent-vm' "$@"
dev_require_target agent-vm
dev_require_user
[[ -d $HOME/.bb-machines ]]
find "$HOME/.bb-machines" -mindepth 1 -print -quit | grep -q .
systemctl --user list-unit-files --type=service --no-legend 'bb*' | grep -q '^bb'
echo 'bb-enroll-execution-machine verify passed'
