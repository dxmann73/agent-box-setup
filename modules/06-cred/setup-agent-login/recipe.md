# setup-agent-login recipe

Run once during daily-host bootstrap, after `claude-code-bootstrap` and before the setup agent takes
over. This is only the early Claude Code login. Do not treat it as the later `claude-login` pass,
and do not use it on an agent VM or Chrome guest.

```bash
cd ~/projects/agent-box-setup/modules/06-cred/setup-agent-login
./apply.sh --target daily-host
./verify.sh --target daily-host
```

Use the stock host browser for the OAuth flow. The resulting credential is local to this host and
must never be copied into a guest or committed.
