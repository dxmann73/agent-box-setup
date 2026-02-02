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

```bash
cursor --version
```

The Cursor application should also appear in your applications menu.

---

## 2. Export Current Settings to Repository

If you have an existing Cursor installation with settings you want to save:

```bash
# Navigate to the repository
cd ~/projects/dave-box-setup

# Create cursor config directory
mkdir -p configs/cursor

# Export settings.json
cp ~/.config/Cursor/User/settings.json configs/cursor/settings.json

# Export keybindings.json
cp ~/.config/Cursor/User/keybindings.json configs/cursor/keybindings.json

# Commit to repository
git add configs/cursor/
git commit -m "Add Cursor IDE configuration files"
git push
```

---

## 3. Restore Settings on New System

Link the settings from the repository (similar to `.bashrc` and other configs):

```bash
# Ensure Cursor config directory exists
mkdir -p ~/.config/Cursor/User

# Create symlinks to repository configs
ln -s ~/projects/dave-box-setup/configs/cursor/settings.json ~/.config/Cursor/User/settings.json
ln -s ~/projects/dave-box-setup/configs/cursor/keybindings.json ~/.config/Cursor/User/keybindings.json
```

**Note:** Extensions will be installed automatically based on per-repository
recommendations when you open projects.

---

## Verification Checklist

- [ ] Cursor IDE installed
- [ ] `cursor` command works from terminal
- [ ] Settings symlinked to repository
- [ ] (Optional) Current settings exported and committed

**Next:** Continue to `06-voice-tools.md`
