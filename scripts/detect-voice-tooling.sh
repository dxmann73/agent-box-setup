#!/bin/bash

# Detect existing voice tooling to avoid conflicting installs.

set -u
shopt -s nullglob nocaseglob

is_wsl=0
if [ -n "${WSL_INTEROP:-}" ] || [ -n "${WSL_DISTRO_NAME:-}" ]; then
  is_wsl=1
elif [ -r /proc/version ]; then
  proc_version="$(tr '[:upper:]' '[:lower:]' < /proc/version)"
  case "$proc_version" in
    *microsoft*|*wsl*)
      is_wsl=1
      ;;
  esac
fi

has_faster_whisper=0
if [ -d "$HOME/faster-whisper-dictation" ] || [ -x "$HOME/.local/bin/dictate-start" ] || [ -x "$HOME/.local/bin/dictate-stop" ]; then
  has_faster_whisper=1
fi

has_nerd_dictation=0
if command -v nerd-dictation >/dev/null 2>&1 || [ -x "$HOME/.local/bin/nerd-dictation-toggle" ]; then
  has_nerd_dictation=1
fi

has_talon=0
if command -v talon >/dev/null 2>&1 || [ -d "$HOME/.talon" ] || [ -d "/opt/talon" ]; then
  has_talon=1
fi

wispr_local_hits=()
for path in \
  "$HOME/.local/bin"/wispr* \
  "$HOME/.local/bin"/whisper*flow* \
  "$HOME/.local/share/applications"/wispr* \
  "$HOME/.local/share/applications"/whisper*flow* \
  "$HOME/.local/apps"/wispr* \
  "$HOME/.local/apps"/whisper*flow*; do
  if [ -e "$path" ]; then
    wispr_local_hits+=("$path")
  fi
done

has_wispr_local=0
if command -v wispr >/dev/null 2>&1 || command -v wispr-flow >/dev/null 2>&1 || command -v whisperflow >/dev/null 2>&1 || [ "${#wispr_local_hits[@]}" -gt 0 ]; then
  has_wispr_local=1
fi

wispr_host_hits=()
if [ "$is_wsl" -eq 1 ] && [ -d /mnt/c/Users ]; then
  for path in \
    /mnt/c/Users/*/AppData/Local/WisprFlow* \
    /mnt/c/Users/*/AppData/Local/whisper*flow*; do
    if [ -e "$path" ]; then
      wispr_host_hits+=("$path")
    fi
  done
fi

has_wispr_host=0
if [ "${#wispr_host_hits[@]}" -gt 0 ]; then
  has_wispr_host=1
fi

detected_stacks=0
detected_names=()
if [ "$has_faster_whisper" -eq 1 ]; then
  detected_stacks=$((detected_stacks + 1))
  detected_names+=("faster-whisper")
fi
if [ "$has_nerd_dictation" -eq 1 ]; then
  detected_stacks=$((detected_stacks + 1))
  detected_names+=("nerd-dictation")
fi
if [ "$has_talon" -eq 1 ]; then
  detected_stacks=$((detected_stacks + 1))
  detected_names+=("Talon")
fi
if [ "$has_wispr_local" -eq 1 ]; then
  detected_stacks=$((detected_stacks + 1))
  detected_names+=("Wispr/whisperFlow (local Linux)")
fi
if [ "$has_wispr_host" -eq 1 ]; then
  detected_stacks=$((detected_stacks + 1))
  detected_names+=("whisperFlow/Wispr Flow (host Windows, via WSL)")
fi

echo "=== Voice Tooling Detection ==="
echo "Environment: $( [ "$is_wsl" -eq 1 ] && echo "WSL/Ubuntu" || echo "Linux" )"
echo "faster-whisper: $( [ "$has_faster_whisper" -eq 1 ] && echo "detected" || echo "not detected" )"
echo "nerd-dictation: $( [ "$has_nerd_dictation" -eq 1 ] && echo "detected" || echo "not detected" )"
echo "Talon: $( [ "$has_talon" -eq 1 ] && echo "detected" || echo "not detected" )"
echo "Wispr/whisperFlow (local Linux): $( [ "$has_wispr_local" -eq 1 ] && echo "detected" || echo "not detected" )"
if [ "$is_wsl" -eq 1 ]; then
  echo "whisperFlow/Wispr Flow (host Windows): $( [ "$has_wispr_host" -eq 1 ] && echo "detected" || echo "not detected" )"
fi

if [ "$has_wispr_local" -eq 1 ] && [ "${#wispr_local_hits[@]}" -gt 0 ]; then
  echo ""
  echo "Local Wispr/whisperFlow paths:"
  printf ' - %s\n' "${wispr_local_hits[@]}"
fi

if [ "$has_wispr_host" -eq 1 ]; then
  echo ""
  echo "Host whisperFlow/Wispr Flow paths:"
  printf ' - %s\n' "${wispr_host_hits[@]}"
fi

echo ""
if [ "$detected_stacks" -eq 0 ]; then
  echo "Recommendation: No voice tooling detected. Install exactly one option."
elif [ "$detected_stacks" -eq 1 ]; then
  echo "Recommendation: Reuse existing setup (${detected_names[0]}). Skip reinstall."
else
  echo "Recommendation: Multiple voice stacks detected (${detected_names[*]})."
  echo "Choose one primary stack before installing or reconfiguring shortcuts/services."
fi
