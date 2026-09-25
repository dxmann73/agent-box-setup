#!/usr/bin/env bash
set -Eeuo pipefail
trap 'printf "ERROR: java-stack apply failed at line %s\n" "$LINENO" >&2' ERR
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"

usage() { printf '%s\n' 'Usage: sudo ./apply.sh --target agent-vm'; }
if lang_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
lang_handle_parse_result "$status" usage || exit "$?"
lang_require_agent_vm || { usage >&2; exit 2; }
lang_require_sudo_user

setup_user="$SUDO_USER"
setup_home="$(getent passwd "$setup_user" | awk -F: 'NR == 1 { print $6 }')"
[[ -n "$setup_home" && -d "$setup_home" ]] || {
    printf 'Could not resolve a home directory for %s.\n' "$setup_user" >&2
    exit 1
}
lang_install_packages curl zip unzip

sudo -u "$setup_user" env HOME="$setup_home" bash -s <<'SDKMAN_INSTALL'
set -Eeuo pipefail
java_candidate='21.0.12-oracle'

if [[ ! -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
    curl -fsSL https://get.sdkman.io | bash
fi

# SDKMAN functions read unset variables internally, so strict mode cannot cover this block.
# shellcheck disable=SC1091
set +ue
source "$HOME/.sdkman/bin/sdkman-init.sh"
sed -i 's/^sdkman_auto_env=.*/sdkman_auto_env=true/' "$HOME/.sdkman/etc/config"

if ! sdk current java | grep -Fq "$java_candidate"; then
    sdk install java "$java_candidate" || exit $?
fi
if ! sdk current quarkus | grep -q '^Using:'; then
    sdk install quarkus || exit $?
fi
if ! sdk current maven | grep -q '^Using:'; then
    sdk install maven || exit $?
fi
set -ue

install -d -m 0755 "$HOME/.redhat"
printf '%s\n' '{"disabled":false}' >"$HOME/.redhat/io.quarkus.analytics.localconfig"
SDKMAN_INSTALL
printf '%s\n' 'java-stack applied for agent-vm.'
