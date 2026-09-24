# vscode-settings-sync recipe

Run after `vscode` and `github-auth` on each catalog-ticked daily host. The managed settings and
keybindings links are a credential-free bootstrap and drift reference; Settings Sync is the live
account-backed sync mechanism.

1. Open VS Code.
1. From the Accounts menu or Command Palette, choose **Settings Sync: Turn On**.
1. Sign in with the GitHub account and accept the selected sync data.
1. Confirm expected settings, keybindings, extensions, snippets, UI state, and profiles arrive.

Then record that human-only check with the verifier:

```bash
cd ~/projects/agent-box-setup/modules/06-cred/vscode-settings-sync
./verify.sh --target daily-host --confirmed
```

The `--confirmed` flag is deliberate: VS Code has no stable CLI status check that proves an account
session and its synchronized data without exposing private profile state.
