#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
dev_parse_target 'Usage: ./apply.sh --target daily-host' "$@"
dev_require_target daily-host
dev_require_user
dev_require_commands code
code --install-extension vscjava.vscode-java-pack --force
code --install-extension redhat.vscode-quarkus --force
code --install-extension vmware.vscode-boot-dev-pack --force
