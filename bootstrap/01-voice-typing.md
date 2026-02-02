# Install voice typing using faster-whisper

NOTE: **This has already been done by the user already. It is here for future reference**

[Voice typing](https://alterflow.ai/blog/offline-voice-typing-on-ubuntu)

## Step 1: Install System Dependencies

```bash
sudo apt update && sudo apt install -y portaudio19-dev python3-venv python3-pip git xdotool ydotool ydotoold pulseaudio-utils pavucontrol wl-clipboard 
```

## Step 2: Set Up ydotool for Wayland

```bash
# ydotool needs access to the input subsystem. Add your user to the input group:
sudo usermod -aG input $USER

# Create udev rules:
sudo tee /etc/udev/rules.d/60-uinput.rules > /dev/null << 'EOF'
KERNEL=="uinput", MODE="0660", GROUP="input"
EOF

# Reload udev rules:
sudo udevadm control --reload-rules && sudo udevadm trigger

# Important: Restart system for the group change to take effect.

# Verify you're in the input group:
groups | grep input
```

## Step 3: Set Up ydotool Daemon (Optional)

```bash
# Create systemd user directory and symlink the service file
mkdir -p ~/.config/systemd/user
ln -sf "$(pwd)/configs/systemd-user/ydotool.service" ~/.config/systemd/user/ydotool.service

# Enable and start it:
systemctl --user daemon-reload && systemctl --user enable ydotool && systemctl --user start ydotool

# Check status
systemctl --user status ydotool

# Note: If the daemon fails to start, that's okay—ydotool still works without it (just with a small notice message).
```

### Step 4: Install faster-whisper

Install Python 3.11 as it is required by those packages

```bash
sudo apt install -y software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.11 python3.11-venv python3.11-dev
```

Clone the project and set up a Python virtual environment:

```bash
cd ~
git clone https://github.com/doctorguile/faster-whisper-dictation.git
cd faster-whisper-dictation
python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install faster-whisper pyaudio pynput transitions soundfile sounddevice numpy 
deactivate
```

### Step 5: Symlink the Dictation Scripts

Symlink the scripts from this repo to `~/.local/bin`:

```bash
mkdir -p ~/.local/bin

# Symlink all dictation scripts
ln -sf "$(pwd)/configs/local-bin/dictate-start" ~/.local/bin/dictate-start
ln -sf "$(pwd)/configs/local-bin/dictate-stop" ~/.local/bin/dictate-stop
ln -sf "$(pwd)/configs/local-bin/dictate-toggle" ~/.local/bin/dictate-toggle

# Make them executable
chmod +x ~/.local/bin/dictate-*
```

The scripts are located in `configs/local-bin/` and use `$HOME` for paths, so they work for any user.

### Step 6: Test Manually

Open a terminal and run:

```bash
~/.local/bin/dictate-start
```

Speak something for 5 seconds, then run:

```bash
~/.local/bin/dictate-stop
```

First time this will take long because it will download the model.
You should see your speech transcribed and typed in the terminal.

### Step 7: Disable IBus Ctrl+Space Shortcut

By default, GNOME/IBus uses Ctrl+Space for switching input methods. We need to disable this first:

```bash
gsettings set org.gnome.desktop.input-sources xkb-options "[]"
gsettings set org.freedesktop.ibus.general.hotkey triggers "[]"
```

### Step 8: Set Up Keyboard Shortcut

Set up Ctrl+Space as the toggle hotkey:

```bash
# Add to custom keybindings (preserves existing ones like Flameshot)
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"

# Configure the dictation shortcut
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'Dictation Toggle'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command "$HOME/.local/bin/dictate-toggle"
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Ctrl>space'
```

## Troubleshooting

### ydotool backend unavailable

"ydotool: notice: ydotoold backend unavailable"
This is just a notice, not an error. ydotool still works, just with a small delay.

### Transcription is slow

The first transcription after a reboot will be slower (model loading). Subsequent transcriptions are faster. You can also try using the "base" model instead of "small" for faster (but less accurate) results:

Change WhisperModel("small") to WhisperModel("base") in `configs/local-bin/dictate-stop`.

### No speech detected

Check `pavucontrol` to see if the correct device is set

Check your microphone is working:

```bash
parecord --channels=1 /tmp/test.wav 
#then 
aplay /tmp/test.wav
```

Speak louder or closer to the microphone
Try recording for longer (at least 3 seconds)

### Hotkey doesn't work

Make sure you replaced YOUR_USERNAME with your actual username
Check if IBus is still capturing Ctrl+Space — run the disable commands in Step 7 again
Try logging out and back in after changing the shortcut

Ctrl+Space still switches input method
If Ctrl+Space is still being captured by IBus, try:

ibus write-cache
ibus restart
Or open Settings → Keyboard → Input Sources and remove any extra input methods.

## Model Options

You can change the Whisper model based on your needs:

| Model | Size | RAM Needed | Accuracy | Speed |
|-------|------|------------|----------|-------|
| tiny | 75 MB | ~1 GB | Lower | Fastest |
| base | 142 MB | ~1 GB | Good | Fast |
| small | 466 MB | ~2 GB | Better | Medium |
| medium | 1.5 GB | ~5 GB | Great | Slower |
| large-v3 | 3 GB | ~10 GB | Best | Slowest |

For CPU-only systems, I recommend "small" as the best balance of accuracy
and speed.
