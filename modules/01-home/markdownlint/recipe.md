# markdownlint recipe

Two things:

1. `markdownlint-cli` installed globally so the `markdownlint` command is on `PATH` without
   `npx --yes` warm-up on every run.
2. `~/projects/.markdownlint.json` symlinked to the repo's `.markdownlint.json` so any project
   under `~/projects/` inherits the same lint rules (line length, disabled MD024/MD060, …).

Requires `node-24` (npm + the user-level `~/.npm-global` prefix). Do not run this before that
module has set the npm global prefix under `$HOME`, otherwise `npm install -g` needs sudo.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/01-home/markdownlint
./apply.sh
```

`apply.sh` is idempotent:

- Verifies `npm` is on `PATH` and the npm global prefix lives under `$HOME` (fails fast otherwise,
  so we never sudo-install into `/usr`).
- Runs `npm install -g markdownlint-cli` (npm no-ops when the current version matches).
- Ensures `~/projects/` exists and symlinks
  `~/projects/agent-box-setup/.markdownlint.json` to `~/projects/.markdownlint.json`
  (`ln -sfn`, so a stale link is repointed). A pre-existing regular file is moved into
  `~/.agent-box-setup-backup/` first.

## What it enables

- `markdownlint` and `markdownlint-cli` binaries under `~/.npm-global/bin/`.
- Per-project runs of `markdownlint '**/*.md'` from anywhere in `~/projects/*` pick up the shared
  rules through the symlinked file.

## Verify

```bash
./verify.sh
```

Checks: `markdownlint` is on `PATH`, `~/projects/.markdownlint.json` resolves to the repo file,
and `markdownlint --version` runs.

## Scope

- In: global `markdownlint-cli` install + `~/projects/.markdownlint.json` symlink.
- Out: repo `.markdownlint.json` rule edits (edit in place), `.markdownlintignore` (not in this
  repo today), the `agents/skills/markdownlint/` skill payload (part of `agents/`),
  `home-dotfiles` shell dotfiles, `node-24` runtime/prefix.
