# vscode recipe

Run on catalog-ticked daily hosts after `kubuntu-desktop`. This module uses Microsoft's signed APT
repository; VS Code updates through the normal unattended package path. `vscode-settings-sync` owns
account sign-in. The tracked files under `user-home/vscode/` remain the credential-free bootstrap
and drift reference.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/05-dev/vscode
sudo ./apply.sh --target daily-host
```

## Verify

```bash
./verify.sh --target daily-host
```

The verifier checks the signed source, installed package, `code` executable, and managed settings
and keybindings links. It does not require an account or Settings Sync.
