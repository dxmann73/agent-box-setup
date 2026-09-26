# git-identity

What: The single real `~/.gitconfig` per box.

Does: Installs the deployment overlay's `.gitconfig` as a regular file at `~/.gitconfig` on the
daily host, and streams the same file to the agent VM over the libvirt-bridge SSH path. Removes a
pre-existing symlink at that path.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `./apply.sh --target daily-host --source PATH`

Verify: `./verify.sh --target daily-host|agent-vm`

`~/.gitconfig` is the one exception to the repository rule that everything in `user-home/` is
symlinked into `~`. The file is not part of the public `user-home/` payload: it carries the
deployment identity, so it lives in the deployment overlay. It is installed as a copy, not a
symlink, so that `gh auth setup-git` and other tools that write to `~/.gitconfig` do not modify a
repository working tree. There is no `.gitconfig.local`.

`home-dotfiles` excludes `.gitconfig`; this module owns it. Credential helpers are not written here
— run `gh auth setup-git` after apply.
