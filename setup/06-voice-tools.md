# 06 - Voice Tools

Set up voice input for Ubuntu.

## Prerequisites

- Completed core setup (01-04, skipping 05)
- Microphone connected and working

---

## 1. Voice Input Options for Linux

Wispr Flow is not available for Linux. Alternative options:

### Option A: Nerd Dictation (Recommended)

Offline voice dictation using Vosk:

```bash
# Install dependencies
sudo apt install python3-pip portaudio19-dev -y

# Install nerd-dictation
pip3 install --user nerd-dictation

# Add to PATH if needed
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Option B: Talon Voice

More advanced option with programming-specific features:
- Download from: https://talonvoice.com/

---

## 2. Nerd Dictation Setup

### Basic Usage

Start dictation:
```bash
nerd-dictation begin
```

Stop dictation:
```bash
nerd-dictation end
```

### Setup Keyboard Shortcuts

Create a hotkey to toggle dictation. In your desktop environment's keyboard settings, bind:
- Start: `nerd-dictation begin`
- Stop: `nerd-dictation end`

Or use a single toggle command:
```bash
nerd-dictation toggle
```

### Recommended: Run as a Service

Create a systemd user service for persistent operation:

```bash
mkdir -p ~/.config/systemd/user
```

Create `~/.config/systemd/user/nerd-dictation.service`:
```ini
[Unit]
Description=Nerd Dictation Voice Input

[Service]
Type=simple
ExecStart=/home/%u/.local/bin/nerd-dictation begin
Restart=on-failure

[Install]
WantedBy=default.target
```

Enable and start:
```bash
systemctl --user enable nerd-dictation
systemctl --user start nerd-dictation
```

---

## 3. Integration with Claude

Voice dictation works seamlessly with Claude Code:

1. Have Claude running in terminal
2. Activate voice dictation (via hotkey)
3. Speak your requests
4. Text appears directly in the terminal

Tips:
- Speak naturally and clearly
- Pause between commands
- Test dictation accuracy before heavy use

---

## Verification Checklist

- [ ] Voice input tool installed (nerd-dictation or Talon)
- [ ] Microphone working and configured
- [ ] Hotkey configured for activation
- [ ] Test dictation in a text editor
- [ ] Test dictation in terminal with Claude

**Next:** Continue to `07-optional.md`
