#!/usr/bin/env bash

# Start VibeTyper after KDE Wallet is ready. On this Plasma host, the wallet
# service can otherwise race VibeTyper's secret lookup immediately after login.

set -Eeuo pipefail

readonly appimage="$HOME/Applications/VibeTyper.AppImage"
[[ -x "$appimage" ]] || {
    printf 'VibeTyper AppImage is missing or not executable: %s\n' "$appimage" >&2
    exit 1
}

for _ in {1..60}; do
    if qdbus6 org.kde.kwalletd6 /modules/kwalletd6 \
        org.kde.KWallet.isOpen kdewallet 2>/dev/null | grep -qx true; then
        break
    fi
    sleep 1
done

setsid -f "$appimage" --no-sandbox "$@" >/dev/null 2>&1
