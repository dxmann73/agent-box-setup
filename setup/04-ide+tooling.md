# 04 - Editor Setup

Cursor IDE is the primary editor. It's an AI-powered code editor built on VS
Code.

## Prerequisites

- Completed `02-core-tools.md`
- Completed `03-dev-environment.md`

---

## 1. Install Cursor IDE

### Manual Installation Steps

1. Open the [Cursor download page](https://cursor.com/download)
2. Download the `.deb` package (it will save to your Downloads folder)
3. Open Downloads and right-click on the `cursor_*.deb` file
4. Select "Open With App Center"
5. Click "Install" and authenticate as needed

**Verify:**

```bash
cursor --version
```

The Cursor application should also appear in your applications menu. Pin it to the Dash.

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

## 4. Install Cursor CLI

As per the [installation instructions]()

```bash
curl https://cursor.com/install -fsS | bash
```

Check if the agent can be called, otherwise you may need to add local/bin to your PATH

---

## Verification Checklist

- [ ] Cursor IDE installed
- [ ] `cursor` command works from terminal
- [ ] Settings symlinked to repository
- [ ] (Optional) Current settings exported and committed

**Next:** Continue to `06-voice-tools.md`
