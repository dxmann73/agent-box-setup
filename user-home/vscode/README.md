# VS Code configuration

Reference copy of the VS Code user configuration. **Settings Sync (GitHub account) is the live
mechanism** — these files exist to bootstrap a fresh box, document intent, and let
`verify-setup.sh` detect drift.

## Files

| File | Purpose |
|------|---------|
| `settings.json` | User settings |
| `keybindings.json` | Keybinding overrides |

## Bootstrap a new machine

1. Install VS Code, sign in, enable **Settings Sync** (Settings, Backup and Sync Settings).
   Sync covers settings, keybindings, extensions, snippets, UI state and profiles.
2. If sync is unavailable, copy `settings.json` and `keybindings.json` into the user config
   directory manually:
   - Linux native: `~/.config/Code/User/`
   - WSL (UI runs on Windows): `%APPDATA%\Code\User\`
3. Open each project once so workspace extension recommendations install.

Note: on WSL the UI settings live on the Windows side, while extensions split between
`~/.vscode-server/extensions` (remote) and `%APPDATA%\Code\User` / `%USERPROFILE%\.vscode\extensions`
(UI). Symlinking from WSL into `/mnt/c` does not work on DrvFs, so WSL uses a copy, not a symlink.

## Known gap

`workbench.editor.limit.value: 99` has no effect unless `workbench.editor.limit.enabled` is also
`true`. Add the `enabled` key if the limit is actually wanted.

## Extensions

Linters, formatters and framework support are declared per repository in
`.vscode/extensions.json`, so opening a project prompts for exactly what it needs.

Editor-wide, owned by no single project, installed by `04-ide+tooling.md`:

- `editorconfig.editorconfig`
- `moshfeu.compare-folders`
- `tomchen.paste-markdown-link`

Java (`redhat.java`, `vscjava.*`) stays an on-demand install — none of the current projects is a
Java project.
