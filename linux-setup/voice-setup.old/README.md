# Archived voice tooling

Retired local Linux voice stacks. Current choice is
[vibetyper](https://vibetyper.com/docs), see
[../03-software-installation.md](../03-software-installation.md).

Nothing here is referenced by the active setup, `verify-setup.sh`, or `SETUP.md`.

| Item | Was |
| --- | --- |
| [05-voice-tools-a-faster-whisper.md](05-voice-tools-a-faster-whisper.md) | faster-whisper dictation guide |
| [05-voice-tools-b-nerd-dictation.md](05-voice-tools-b-nerd-dictation.md) | nerd-dictation (Vosk) guide |
| [08-local-whisper.md](08-local-whisper.md) | Windows/online Whisper reference notes |
| [detect-voice-tooling.sh](detect-voice-tooling.sh) | Detector for conflicting voice stacks |
| `local-bin/` | `dictate-*` and `nerd-dictation-toggle` scripts |
| `systemd-user/` | `ydotool`, `dictate-ptt`, `nerd-dictation` user units |

Commands inside the guides are written for the repo root as working directory, e.g.

```bash
./linux-setup/voice-setup.old/detect-voice-tooling.sh
```
