# vscode-remote-ssh recipe

Run on daily hosts after `vscode` and `ssh-client`. This installs only VS Code's Remote SSH
extension. SSH hosts, keys, and `~/.ssh/config` remain per-machine configuration and are not
recorded here.

```bash
./apply.sh --target daily-host
./verify.sh --target daily-host
```
