# 04 - Editor Setup

VS Code is the primary editor. Settings and keybindings live in
[`../../user-home/vscode/README.md`](../../user-home/vscode/README.md).

Cursor CLI is installed with the other agents in
[`../../agents/cursor/README.md`](../../agents/cursor/README.md).

This guide describes the native Linux install.

## Prerequisites

- Completed `02-core-tools.md`

---

## 1. Install VS Code

### Linux (Kubuntu host and agent VM)

Keep an existing working VS Code installation (including Snap). For a new installation, use
Microsoft's apt repository so the daily `unattended-upgrades` run keeps it current
(`08-auto-updates.md` already allows `origin=packages.microsoft.com`).

```bash
sudo apt install -y wget gpg apt-transport-https
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor \
  | sudo tee /usr/share/keyrings/microsoft.gpg > /dev/null
echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
  | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
sudo apt update && sudo apt install -y code
```

**Verify:**

```bash
code --version
```

Expected: a version number, a commit hash and `x64`.

Tell your human to pin VS Code to the Dash.

---

## 2. Settings and keybindings

Settings Sync is the live mechanism. The repo copy under
[`../../user-home/vscode/`](../../user-home/vscode/) is the bootstrap source and the drift
reference.

1. Sign in: `Ctrl-Shift-P` > "Settings Sync: Turn On", authenticate with the GitHub account. Sync
   covers settings, keybindings, extensions, snippets, UI state and profiles.
2. On a machine where sync is not available, link the repository files into place instead:

   ```bash
   mkdir -p ~/.config/Code/User
   ln -sfn ~/projects/agent-box-setup/user-home/vscode/settings.json \
     ~/.config/Code/User/settings.json
   ln -sfn ~/projects/agent-box-setup/user-home/vscode/keybindings.json \
     ~/.config/Code/User/keybindings.json
   ```

**Verify:**

```bash
code --list-extensions | head
```

### Custom keybindings

| Key                | Command         |
| ------------------ | --------------- |
| `ctrl+[Semicolon]` | Toggle terminal |
| `Ctrl-Alt-L`       | Format document |

VS Code has no `ctrl+ö` key name, so the ö key is bound as `ctrl+[Semicolon]`.

### Keyboard shortcuts reference

```text
Ctrl-,              Settings
Ctrl-Shift-P        Command palette
Ctrl-P              Open file (cycle further entries with the right arrow)
Ctrl-Shift-F        Search across the workspace
Ctrl-Alt-F          Search in file, fuzzy on/off
Ctrl-O              Open file
Shift-Alt-O         Organize imports
Ctrl-Shift-K        Delete line
Shift-Alt-F         Format file
Ctrl-D              Select next occurrence
Alt-Enter           Select all occurrences
Alt-click           Place an additional cursor
Ctrl-Alt-Up/Down    Extend multi-cursor up/down
Shift-Alt-Up/Down   Duplicate line up/down
Ctrl-ö              Toggle terminal
```

Full list: [VS Code key bindings](https://code.visualstudio.com/docs/getstarted/keybindings).

---

## 3. Extensions

Extensions are declared per project in `.vscode/extensions.json`, so opening a repository prompts
for exactly what that repository needs. Nothing has to be installed by hand up front.

Linters and formatters belong to the project that uses them, so `markdownlint`, `prettier`, `astro`
and `tailwindcss` are declared per repository. Only the genuinely editor-wide ones are installed
here:

```bash
code --install-extension editorconfig.editorconfig \
     --install-extension moshfeu.compare-folders \
     --install-extension tomchen.paste-markdown-link
```

[SCM Tidy](https://github.com/dxmann73/scm-tidy) collapses clean repositories in the Source Control
view. It is not on the Marketplace; install the `.vsix` from its latest GitHub release. Rerun to
update:

```bash
gh release download --repo dxmann73/scm-tidy --pattern '*.vsix' --dir /tmp --clobber
code --install-extension /tmp/scm-tidy-*.vsix --force
```

Microsoft-licensed extensions (Remote-SSH, Remote-Containers, C#, Pylance) are available only in
real VS Code from the Microsoft marketplace, not in forks that use a third-party one.

Remote SSH is read-write: the VS Code server, Git, terminals, tests, and the working tree run on the
selected Linux machine. Client-specific key generation, SSH configuration, hostnames, and
private-key paths belong in that client's setup repository, not here.

---

## 4. Dave Overlay Extensions

Java/Quarkus editor setup belongs to the Dave box setup.

## Complete Verification

```bash
echo "=== VS Code ===" && \
code --version && \
echo -e "\nBinary: $(which code)" && \
echo "Extensions installed: $(code --list-extensions | wc -l)"
```

## Verification Checklist

- [ ] VS Code installed: `code --version` shows a version
- [ ] `code` command works from the terminal
- [ ] Settings Sync turned on, or `settings.json` / `keybindings.json` linked
- [ ] `Ctrl-Alt-L` formats the document
- [ ] `Ctrl-ö` toggles the terminal
- [ ] Editor-wide extensions installed
- [ ] Dave overlay extensions installed, if applicable

**Next:** Continue to `05-bb.md`
