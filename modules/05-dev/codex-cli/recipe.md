# codex-cli recipe

Run after `kubuntu-desktop` on every catalog-ticked daily host or agent VM. This module uses the
official standalone installer, so Codex has no runtime dependency on Node. It does not launch Codex
or create credentials; `codex-login` owns authentication. Repo-managed configuration is linked by
`agent-config`.

```bash
./apply.sh --target daily-host
./verify.sh --target daily-host
```

Use `--target agent-vm` inside the agent VM.
