#!/usr/bin/env bash
# Host sudo-work terminal for the bb-sudo-terminal skill.
# Plays a short bloop every 10 seconds until sudo -v returns, then refreshes
# the sudo ticket and opens an interactive shell. Never reads or prints a password.

set -Eeuo pipefail

reminder_pid=
refresh_pid=
tone_file=

cleanup() {
  local pid
  for pid in "${reminder_pid:-}" "${refresh_pid:-}"; do
    if [[ -n "${pid}" ]]; then
      kill "${pid}" 2>/dev/null || true
      wait "${pid}" 2>/dev/null || true
    fi
  done
  reminder_pid=
  refresh_pid=
  if [[ -n "${tone_file:-}" ]]; then
    rm -f "${tone_file}"
    tone_file=
  fi
}

on_signal() {
  cleanup
  exit 143
}

trap cleanup EXIT
trap on_signal INT TERM HUP

write_tone() {
  python3 - "${tone_file}" <<'PY'
import math
import struct
import sys
import wave

path = sys.argv[1]
rate = 48000
duration = 0.08
count = int(rate * duration)
amplitude = 0.22

with wave.open(path, "w") as handle:
    handle.setnchannels(1)
    handle.setsampwidth(2)
    handle.setframerate(rate)
    frames = bytearray()
    for index in range(count):
        t = index / rate
        progress = index / count
        freq = 880 - (360 * progress)
        fade_in = min(1.0, index / (rate * 0.006))
        decay = math.exp(-t * 32)
        sample = amplitude * fade_in * decay * math.sin(2 * math.pi * freq * t)
        frames += struct.pack("<h", max(-32767, min(32767, int(round(sample * 32767)))))
    handle.writeframes(frames)
PY
}

start_reminder() {
  # Heredoc stdin keeps this process off the terminal, so it cannot eat the password.
  python3 - "${tone_file}" <<'PY' >/dev/null 2>&1 &
import signal
import subprocess
import sys
import time

tone = sys.argv[1]
proc = None


def stop(_signum, _frame):
    if proc is not None and proc.poll() is None:
        proc.terminate()
    raise SystemExit(0)


signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)

while True:
    time.sleep(10)
    proc = subprocess.Popen(
        ["paplay", tone],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    proc.wait()
    proc = None
PY
  reminder_pid=$!
}

stop_reminder() {
  if [[ -n "${reminder_pid}" ]]; then
    kill "${reminder_pid}" 2>/dev/null || true
    wait "${reminder_pid}" 2>/dev/null || true
    reminder_pid=
  fi
}

prepare_reminder() {
  command -v python3 >/dev/null 2>&1 || return 1
  command -v paplay >/dev/null 2>&1 || return 1
  tone_file=$(mktemp --suffix=.wav) || return 1
  write_tone || return 1
}

main() {
  if prepare_reminder; then
    start_reminder
  else
    printf 'Password reminder sound unavailable.\n' >&2
    if [[ -n "${tone_file}" ]]; then
      rm -f "${tone_file}"
      tone_file=
    fi
  fi

  sudo -v
  stop_reminder

  (
    while sleep 45; do
      sudo -n -v || exit
    done
  ) </dev/null &
  refresh_pid=$!

  printf '\nBB sudo work terminal ready. Agent runs approved sudo commands here.\n\n'
  bash --noprofile --norc -i
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
