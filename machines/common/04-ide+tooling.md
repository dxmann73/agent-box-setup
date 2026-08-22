# 04 - Editor Setup

VS Code is the primary editor. Settings and keybindings live in
[`../../user-home/vscode/README.md`](../../user-home/vscode/README.md).

Cursor **CLI** (`cursor-agent`) is a separate product, not an editor — it is installed from
[`../../agents/cursor/README.md`](../../agents/cursor/README.md).

This guide describes the native Linux install. VS Code runs on the Windows side instead under
[`../wsl/README.md`](../wsl/README.md) (WSL host variant).

## Prerequisites

- Completed `02-core-tools.md`

---

## 1. Install VS Code

### Linux (Kubuntu host and agent VM)

Install from Microsoft's apt repository, not the standalone `.deb`, so the daily
`unattended-upgrades` run keeps it current (`08-auto-updates.md` already allows
`origin=packages.microsoft.com`).

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

1. Sign in: `Ctrl-Shift-P` > "Settings Sync: Turn On", authenticate with the GitHub account.
   Sync covers settings, keybindings, extensions, snippets, UI state and profiles.
2. On a machine where sync is not available, copy the two files into place instead:

   ```bash
   mkdir -p ~/.config/Code/User
   cp ~/projects/agent-box-setup/user-home/vscode/settings.json    ~/.config/Code/User/
   cp ~/projects/agent-box-setup/user-home/vscode/keybindings.json ~/.config/Code/User/
   ```

**Verify:**

```bash
code --list-extensions | head
```

### Custom keybindings

Only two overrides are carried; everything else is stock VS Code.

| Key | Command |
| --- | --- |
| `Ctrl-Alt-L` | Format document |
| `Ctrl-Shift-T` | Java: go to test (replaces "reopen closed editor") |

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

Linters and formatters belong to the project that uses them, so `markdownlint`, `prettier`,
`astro` and `tailwindcss` are declared per repository. Only the genuinely editor-wide ones are
installed here:

```bash
code --install-extension editorconfig.editorconfig \
     --install-extension moshfeu.compare-folders \
     --install-extension tomchen.paste-markdown-link
```

Microsoft-licensed extensions (Remote-SSH, Remote-Containers, C#, Pylance) are available only in
real VS Code from the Microsoft marketplace, not in forks that use a third-party one.

---

## 4. Java extensions

For Java/Quarkus projects:

```bash
code --install-extension vscjava.vscode-java-pack \
     --install-extension redhat.vscode-quarkus \
     --install-extension vmware.vscode-boot-dev-pack
```

`vscjava.vscode-java-pack` pulls in `redhat.java`, Maven, Gradle, debugger, test runner and
project explorer. `vmware.vscode-boot-dev-pack` is the Spring Boot set.

### Java settings

Add to user or workspace settings — the `java.diagnostic.filter` entry
[silences warnings from generated sources](https://stackoverflow.com/questions/57215534/java-ignore-warnings-on-directory-package-level/79781667#79781667):

```json
{
  "java.maven.downloadSources": true,
  "java.diagnostic.filter": ["**/target/generated-sources/**/*"],
  "java.completion.importOrder": ["*", "java", "javax"],
  "java.compile.nullAnalysis.mode": "automatic"
}
```

### IntelliJ code style

For reference only, not part of this setup. Where a project has to match an IntelliJ formatting
profile, export it from IntelliJ as XML and point VS Code at that file:

```json
{
  "java.format.settings.url": "file:///home/dave/MHB-IntelliJ-Codestyle.xml",
  "java.format.settings.profile": "IntelliJ IDEA"
}
```

---

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
- [ ] Settings Sync turned on, or `settings.json` / `keybindings.json` copied into place
- [ ] `Ctrl-Alt-L` formats the document
- [ ] Editor-wide extensions installed
- [ ] Java extensions installed, if applicable

**Next:** Continue to `06-optional.md` or `07-imaging-tools.md`
