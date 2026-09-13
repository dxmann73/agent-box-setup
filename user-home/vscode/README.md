# VS Code configuration

Reference copy of the VS Code user configuration. **Settings Sync (GitHub account) is the live
mechanism** — these files exist to bootstrap a fresh box, document intent, and let `verify-setup.sh`
detect drift.

## Files

| File               | Purpose              |
| ------------------ | -------------------- |
| `settings.json`    | User settings        |
| `keybindings.json` | Keybinding overrides |

## Bootstrap a new machine

1. Install VS Code, sign in, enable **Settings Sync** (Settings, Backup and Sync Settings). Sync
   covers settings, keybindings, extensions, snippets, UI state and profiles.
2. If sync is unavailable, link `settings.json` and `keybindings.json` into the user config
   directory: `~/.config/Code/User/`
3. Open each project once so workspace extension recommendations install.

Use the native Linux user-configuration path documented below.

## Known gap

`workbench.editor.limit.value: 99` has no effect unless `workbench.editor.limit.enabled` is also
`true`. Add the `enabled` key if the limit is actually wanted.

## Extensions

Linters, formatters and framework support are declared per repository in `.vscode/extensions.json`,
so opening a project prompts for exactly what it needs.

Editor-wide, owned by no single project, installed by `04-ide+tooling.md`:

- `editorconfig.editorconfig`
- `moshfeu.compare-folders`
- `tomchen.paste-markdown-link`
- `dxmann73.scm-tidy`: own extension, not on the Marketplace. Installed from its
  [GitHub release](https://github.com/dxmann73/scm-tidy/releases) `.vsix`; see `04-ide+tooling.md`.

Java settings and extensions live in the Dave box setup.
