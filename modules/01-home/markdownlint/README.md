# markdownlint

What: Markdown linting support.

Does: Installs the `markdownlint-cli` global npm package and symlinks the
shared `.markdownlint.json` into `~/projects/` so every project under
`~/projects/` picks up one lint config.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `./apply.sh`

Verify: `./verify.sh`

Scope boundary: this module owns only `~/projects/.markdownlint.json` (symlink into the repo) and
the global `markdownlint-cli` install. The lint rules file itself
(`.markdownlint.json` at the repo root) is edited in place, not copied. `node-24` owns the npm
runtime and the `~/.npm-global` prefix; `home-dotfiles` explicitly excludes the markdownlint
symlink. The `markdownlint` agent skill under `agents/skills/markdownlint/` ships with the
`agents/` payload and is not installed by this module.
