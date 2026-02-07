# 05b - Voice Tools: nerd-dictation

Set up voice input for Ubuntu.

## Prerequisites

- Completed core setup (00-04)
- Microphone connected and working

---

## 1. Voice Input Options for Linux

Wispr Flow is not available for Linux. Alternative optionis offline voice dictation using Vosk:

```bash
# Install dependencies
sudo apt install python3-pip portaudio19-dev -y

# Install nerd-dictation
pip3 install --user nerd-dictation

# Add to PATH if needed
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

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

### Install Voice Scripts

Symlink the helper scripts from this repo:

```bash
# Toggle script for keyboard shortcuts
ln -sf "$(pwd)/configs/local-bin/nerd-dictation-toggle" ~/.local/bin/nerd-dictation-toggle
chmod +x ~/.local/bin/nerd-dictation-toggle
```

### Setup Keyboard Shortcuts

Create a hotkey to toggle dictation. In your desktop environment's keyboard settings, bind a key to:

```bash
~/.local/bin/nerd-dictation-toggle
```

This script toggles dictation on/off with a single keypress.

### Optional: Run as a Service

For persistent operation, symlink and enable the systemd user service:

```bash
# Create systemd user directory if needed
mkdir -p ~/.config/systemd/user

# Symlink the service file
ln -sf "$(pwd)/configs/systemd-user/nerd-dictation.service" ~/.config/systemd/user/nerd-dictation.service

# Enable and start
systemctl --user daemon-reload
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
- [ ] Toggle script symlinked to `~/.local/bin/`
- [ ] Hotkey configured for activation
- [ ] Test dictation in a text editor
- [ ] Test dictation in terminal with Claude

**Next:** Continue to `06-optional.md`
