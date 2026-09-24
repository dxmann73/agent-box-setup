#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
usage() { printf '%s\n' 'Usage: ./verify.sh --target daily-host|agent-vm'; }
github_git_helper() { git config --get-all credential.https://github.com.helper | grep -Fqx '!gh auth git-credential'; }
if cred_parse_target "$@"; then status=0; else status=$?; fi
if ((status == 10)); then usage; exit 0; fi
cred_handle_parse_result "$status" usage || exit "$?"
cred_require_target daily-host agent-vm || { usage >&2; exit 2; }
cred_require_user
cred_check 'GitHub CLI is authenticated' gh auth status
cred_check 'GitHub Git protocol is HTTPS' bash -c 'gh config get git_protocol | grep -qx https'
cred_check 'Git uses the GitHub CLI credential helper' github_git_helper
cred_finish_verify github-auth
