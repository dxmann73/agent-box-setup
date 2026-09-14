# Browser login from a separate personal guest

Run each CLI on its intended machine. Use the personal browser for account sign-in, without
installing coding agents in that browser guest. Existing working CLI credentials stay in place;
changing the browser does not require logging those CLIs in again.

## Prefer a device code or a provider's manual completion prompt

| Tool                  | Flow to use after browser setup                                                                                                                                                                      |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Codex                 | `codex login --device-auth`; open the printed link in the personal browser and enter the code. Device login must be enabled for the account/workspace. Check `codex login status` afterwards.        |
| GitHub CLI            | `gh auth login --web`; follow the displayed browser/code prompts, then `gh auth status`. Reuse an existing authenticated account.                                                                    |
| Claude Code           | `claude auth login`; use the CLI's displayed browser and manual completion prompts. If the browser ends at a failed HTTP loopback callback, use the procedure below.                                 |
| Cursor CLI            | `agent login`; use the printed authentication flow. `NO_OPEN_BROWSER=1 agent login` disables automatic browser opening when copying the URL is needed.                                               |
| Pi                    | Run `/login` for the selected provider. Follow that provider's code/redirect prompt; providers differ. Use the loopback procedure only if the flow actually ends at a failed HTTP loopback callback. |
| Firecrawl             | Follow the installed CLI's authentication prompts. If it requests an API key, supply it privately using the normal credential workflow, not in agent chat.                                           |
| VS Code Settings Sync | Use its displayed account flow. A `vscode:` callback belongs on the machine running VS Code, not in the browser guest; it is not an HTTP callback for the helper below.                              |

Codex's device flow is documented in
[official authentication guidance](https://developers.openai.com/codex/auth#login-on-headless-devices).
GitHub documents its [CLI login flow](https://cli.github.com/manual/gh_auth_login). The installed
Claude and Cursor help were checked for the commands above. Full provider/SSO flows still need
interactive acceptance; a credential file's existence alone is not proof of successful login.

## Complete an HTTP loopback callback on the CLI machine

Some flows finish by redirecting the browser to `http://localhost:PORT/...` or a literal loopback
address. In a separate browser guest this reaches the wrong machine. Keep the CLI login running. Do
not forward the browser guest to arbitrary host ports or copy a random token into a CLI that has not
asked for one.

1. Inspect the active CLI's login URL/output for its expected callback port.
2. Finish account approval in the personal browser. If it ends at a failed HTTP loopback URL, copy
   that **entire callback URL**, including its query, privately to the CLI machine.
3. In another terminal on the CLI machine, run the helper with that expected port:

   ```bash
   python3 ~/projects/agent-box-setup/agents/complete-loopback-login.py --port PORT
   ```

4. Paste the callback at its hidden prompt. It validates HTTP, a literal loopback destination or
   `localhost`, and the exact port. It makes one local GET, does not use proxies or follow
   redirects, and does not print the URL or response body.
5. Confirm the original CLI reports successful authentication. An HTTP response by itself is not the
   final login check. If the flow expired, restart that login and use its new URL and port.

This helper supports GET callbacks with query parameters. It does not support HTTPS loopback,
fragment/POST callbacks or application URI schemes. For those, use the application's documented
device/manual completion flow and verify it before accepting the browser handoff. Never paste
callback URLs into agent chat, commit them, or put them in shell command arguments/history.
