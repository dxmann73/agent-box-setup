# home-dotfiles

What: Shared home-directory payload.

Does: Links managed shell dotfiles (`.bashrc`, `.bash_aliases`, `.profile`) and
helper scripts (`ua.sh`, `update-tools.sh`) from `user-home/` into the user home.
Existing regular files are moved into `~/.agent-box-setup-backup/` first;
existing symlinks are refreshed.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `./apply.sh`

Verify: `./verify.sh`

Scope excludes `.bash_secrets` (login stage), `.markdownlint.json` (`markdownlint`
module), `.gitconfig` (`git-identity` module), and the wezterm/vscode/systemd/pi/klipper
payloads (each their own module).
