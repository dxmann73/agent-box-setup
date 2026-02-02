# 04 - Editor Setup

Cursor IDE is the primary editor. It's an AI-powered code editor built on VS
Code.

## Prerequisites

- Completed `02-core-tools.md`
- Completed `03-dev-environment.md`

---

## 1. Install Cursor IDE

### Manual Installation Steps

1. Open your web browser and go to https://cursor.com/
2. Click on the download button and select Linux
3. Download the `.deb` package (it will save to your Downloads folder)
4. Navigate to your Downloads folder in the file manager
5. Right-click on the `cursor_*.deb` file
6. Select "Open With Software Install" or "Install with GDebi"
7. Click "Install" and enter your password when prompted
8. Wait for the installation to complete

**Verify:**

Open a new terminal and run:

```bash
cursor --version
```

The Cursor application should also appear in your applications menu.

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
