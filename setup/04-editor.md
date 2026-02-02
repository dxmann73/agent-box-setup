# 04 - Editor Setup

Cursor IDE is the primary editor. It's an AI-powered code editor built on VS
Code.

## Prerequisites

- Completed `02-core-tools.md`
- Completed `03-dev-environment.md`

---

## 1. Install Cursor IDE

### Download and Install

```bash
# Download the latest Cursor AppImage
wget https://download.cursor.sh/linux/appimage/Cursor-latest.AppImage -O ~/Downloads/Cursor.AppImage

# Make it executable
chmod +x ~/Downloads/Cursor.AppImage

# Move to a permanent location
sudo mkdir -p /opt/cursor
sudo mv ~/Downloads/Cursor.AppImage /opt/cursor/Cursor.AppImage

# Create a symlink for easy CLI access
sudo ln -s /opt/cursor/Cursor.AppImage /usr/local/bin/cursor
```

**Verify:**

```bash
cursor --version
```

### Create Desktop Entry (Optional)

```bash
cat > ~/.local/share/applications/cursor.desktop <<EOF
[Desktop Entry]
Name=Cursor
Exec=/opt/cursor/Cursor.AppImage
Terminal=false
Type=Application
Icon=/opt/cursor/cursor-icon.png
StartupWMClass=Cursor
Comment=AI-powered code editor
Categories=Development;IDE;
EOF
```

---

## 2. Restore Settings from Repository

If you have previously exported settings to this repository:

```bash
# Ensure config directory exists
mkdir -p ~/.config/Cursor/User

# Restore settings
cp configs/cursor/settings.json ~/.config/Cursor/User/settings.json

# Restore keybindings
cp configs/cursor/keybindings.json ~/.config/Cursor/User/keybindings.json

# Install extensions from list
while read extension; do
  cursor --install-extension "$extension"
done < configs/cursor/extensions.txt
```

---

## 3. Essential Extensions (Fresh Install)

Install via command line:

```bash
# Claude Code extension
cursor --install-extension anthropic.claude-code

# Language support
cursor --install-extension ms-python.python
cursor --install-extension ms-vscode.vscode-typescript-next
cursor --install-extension dbaeumer.vscode-eslint
cursor --install-extension esbenp.prettier-vscode

# Git
cursor --install-extension eamodio.gitlens

# Utilities
cursor --install-extension streetsidesoftware.code-spell-checker
cursor --install-extension usernamehw.errorlens
```

---

## 4. Enable CLI Integration

The `cursor` command should work from the symlink created above.

**Verify:**

```bash
cursor --version
cursor --help
```

---

## Exporting Cursor Settings to Repository

If you're setting this up on a machine with existing Cursor configuration and
want to save your settings to this repository:

### Step 1: Export Settings Files

```bash
# Navigate to the repository
cd ~/projects/dave-box-setup

# Create cursor config directory
mkdir -p configs/cursor

# Export settings.json
cp ~/.config/Cursor/User/settings.json configs/cursor/settings.json

# Export keybindings.json
cp ~/.config/Cursor/User/keybindings.json configs/cursor/keybindings.json

# Export extensions list
cursor --list-extensions > configs/cursor/extensions.txt
```

### Step 2: Export Cursor-Specific Settings (Optional)

Cursor stores additional settings in a global config file:

```bash
# Export global Cursor settings
if [ -f ~/.cursor-global/cursor-settings.json ]; then
  cp ~/.cursor-global/cursor-settings.json configs/cursor/cursor-settings.json
fi
```

### Step 3: Document Custom Settings

Create a README for your settings:

```bash
cat > configs/cursor/README.md <<EOF
# Cursor IDE Configuration

## Files

- \`settings.json\` - VS Code compatible settings
- \`keybindings.json\` - Custom keyboard shortcuts
- \`extensions.txt\` - List of installed extensions
- \`cursor-settings.json\` - Cursor-specific global settings (optional)

## Restore Instructions

Run from repository root:

\`\`\`bash
# Copy settings
cp configs/cursor/settings.json ~/.config/Cursor/User/settings.json
cp configs/cursor/keybindings.json ~/.config/Cursor/User/keybindings.json

# Install extensions
while read extension; do
  cursor --install-extension "\$extension"
done < configs/cursor/extensions.txt

# Restore global settings (if exists)
if [ -f configs/cursor/cursor-settings.json ]; then
  mkdir -p ~/.cursor-global
  cp configs/cursor/cursor-settings.json ~/.cursor-global/cursor-settings.json
fi
\`\`\`

## Export Instructions

\`\`\`bash
# From repository root
cp ~/.config/Cursor/User/settings.json configs/cursor/settings.json
cp ~/.config/Cursor/User/keybindings.json configs/cursor/keybindings.json
cursor --list-extensions > configs/cursor/extensions.txt
\`\`\`
EOF
```

### Step 4: Commit to Repository

```bash
# Add the new config files
git add configs/cursor/

# Commit
git commit -m "Add Cursor IDE configuration files"

# Push to remote (if configured)
git push
```

### Step 5: Apply Settings on New System

After installing Cursor on a new system, restore your settings:

```bash
# Navigate to repository
cd ~/projects/dave-box-setup

# Ensure Cursor config directory exists
mkdir -p ~/.config/Cursor/User

# Restore settings
cp configs/cursor/settings.json ~/.config/Cursor/User/settings.json
cp configs/cursor/keybindings.json ~/.config/Cursor/User/keybindings.json

# Install all extensions
while read extension; do
  cursor --install-extension "$extension"
done < configs/cursor/extensions.txt

# Restore global settings (if exists)
if [ -f configs/cursor/cursor-settings.json ]; then
  mkdir -p ~/.cursor-global
  cp configs/cursor/cursor-settings.json ~/.cursor-global/cursor-settings.json
fi
```

---

## Alternative: Symlink Approach (Advanced)

For automatic sync, you can symlink the settings files directly to the
repository:

```bash
# Backup existing settings first
mv ~/.config/Cursor/User/settings.json ~/.config/Cursor/User/settings.json.backup
mv ~/.config/Cursor/User/keybindings.json ~/.config/Cursor/User/keybindings.json.backup

# Create symlinks
ln -s ~/projects/dave-box-setup/configs/cursor/settings.json ~/.config/Cursor/User/settings.json
ln -s ~/projects/dave-box-setup/configs/cursor/keybindings.json ~/.config/Cursor/User/keybindings.json
```

**Note:** This approach requires the repository to be in the same location on
all systems.

---

## Verification Checklist

- [ ] Cursor IDE installed
- [ ] `cursor` command works from terminal
- [ ] Essential extensions installed
- [ ] Settings applied
- [ ] (Optional) Settings exported to repository
- [ ] (Optional) Settings committed and pushed

**Next:** Continue to `06-voice-tools.md`
