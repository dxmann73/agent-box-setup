#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

usage() { printf '%s\n' 'Usage: ./verify.sh --target agent-vm'; }
if lang_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
lang_handle_parse_result "$status" usage || exit "$?"
lang_require_agent_vm || { usage >&2; exit 2; }
lang_require_user

sdkman_init="$HOME/.sdkman/bin/sdkman-init.sh"
[[ -s "$sdkman_init" ]] || {
    printf 'SDKMAN init file missing: %s\n' "$sdkman_init" >&2
    exit 1
}
# SDKMAN functions read unset variables internally.
set +u
# shellcheck disable=SC1090
source "$sdkman_init"
lang_check 'SDKMAN reports its version' sdk version
lang_check 'SDKMAN auto-env is enabled' grep -qx 'sdkman_auto_env=true' "$HOME/.sdkman/etc/config"
lang_check 'Java 21 is active' bash -c 'java --version | head -n 1 | grep -Eq "^openjdk 21\\.|^java 21\\."'
lang_check 'Quarkus is on PATH' command -v quarkus
lang_check 'Quarkus reports its version' quarkus --version
lang_check 'Maven is on PATH' command -v mvn
lang_check 'Maven reports its version' mvn --version
set -u
lang_check 'Quarkus analytics configuration is written' \
    grep -qx '{"disabled":false}' "$HOME/.redhat/io.quarkus.analytics.localconfig"
lang_finish_verify java-stack
