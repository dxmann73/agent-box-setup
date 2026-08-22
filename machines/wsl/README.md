# WSL host variant

Everything that only applies when the box is Windows + WSL Ubuntu rather than native Kubuntu.

**This directory is disposable.** It exists because one laptop still runs WSL. Once that machine is
on Kubuntu, delete `machines/wsl/` and the two touchpoints listed under
[Remaining touchpoints](#remaining-touchpoints). Nothing outside this directory may depend on it —
the guides under `machines/common/`, `machines/host/` and `machines/vm/` describe the native Linux
case only.

---

## Projects on the Linux filesystem

Keep projects under `~/projects` on the WSL filesystem (`\\wsl$\<distro>\home\<user>\` from
Windows), never under `/mnt/c`. Builds are roughly 10x faster; DrvFs has no inotify and poor
metadata performance.

---

## VS Code

Extends [`../common/04-ide+tooling.md`](../common/04-ide+tooling.md). The apt-repo install in that
guide is for native Linux and does not apply here.

VS Code runs on the Windows side and attaches into WSL over the Remote-WSL extension:

```powershell
winget install Microsoft.VisualStudioCode
```

Then install the **WSL** extension (`ms-vscode-remote.remote-wsl`). Afterwards `code .` works from
inside the WSL shell — the wrapper is injected onto `PATH` on first attach.

Remote-WSL is Microsoft-licensed, so it exists only in real VS Code, not in forks that use a
third-party marketplace.

### Where things live

| Thing | Native Linux | WSL |
| --- | --- | --- |
| User settings | `~/.config/Code/User/` | `%APPDATA%\Code\User\` (Windows side) |
| UI extensions | `~/.vscode/extensions/` | `%USERPROFILE%\.vscode\extensions\` |
| Workspace extensions | same | `~/.vscode-server/extensions/` (inside WSL) |

Extensions install into whichever side they declare. Language servers, formatters and linters land
in `~/.vscode-server/`; themes and remote connectors stay on Windows. This is normal, not drift.

### Settings without Settings Sync

Settings Sync is the intended mechanism and works unchanged here. Only if it is unavailable, copy
the repo files to the Windows-side config directory:

```bash
cp ~/projects/agent-box-setup/user-home/vscode/settings.json \
   ~/projects/agent-box-setup/user-home/vscode/keybindings.json \
   /mnt/c/Users/<user>/AppData/Roaming/Code/User/
```

Copy, do not symlink — `ln -s` into `/mnt/c` does not work on DrvFs.

### IntelliJ code style

Where a project has to match an IntelliJ formatting profile, the exported XML normally sits on the
Windows side, so the setting takes a Windows path:

```json
{
  "java.format.settings.url": "file:///C:/Users/dave/MHB-IntelliJ-Codestyle.xml",
  "java.format.settings.profile": "IntelliJ IDEA"
}
```

---

## Codex CLI

Extends [`../../agents/codex/README.md`](../../agents/codex/README.md).

Run Codex inside WSL, not in PowerShell — see OpenAI's
[WSL setup guide](https://developers.openai.com/codex/windows#windows-subsystem-for-linux).

Codex hooks do not fire on Windows. If Codex is ever run outside WSL, activate the caveman hook by
hand with `$caveman`.

---

## Remaining touchpoints

Two places outside this directory still know about WSL. Remove them when WSL goes:

| Where | What | Why it lives there |
| --- | --- | --- |
| `verify-setup.sh` | `win_code_dirs=(/mnt/c/Users/*/AppData/Roaming/Code/User)` fallback in the VS Code config check | The script must run unmodified on either box; the fallback is inert on native Linux |
| `AGENTS.md`, `README.md` | The rule and the table row declaring this directory disposable | Self-referential by nature |
