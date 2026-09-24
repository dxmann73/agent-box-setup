#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
dev_parse_target 'Usage: ./verify.sh --target daily-host' "$@"
dev_require_target daily-host
dev_require_user
for extension in vscjava.vscode-java-pack redhat.vscode-quarkus vmware.vscode-boot-dev-pack; do code --list-extensions | grep -qxi "$extension"; done
echo 'vscode-java-extensions verify passed'
