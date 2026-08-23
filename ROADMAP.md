# box setup roadmap

- Remove `brainstorming` + `verification-before-completion` skills — still in `agents/skills/`;
  delete dirs, drop the `obra/superpowers` install line in `agents/README.md`, re-run
  `verify-setup.sh`.
- [Two-skill capture/build workflow](https://www.youtube.com/watch?v=I9-tdhxiH7w) (Matt Maher,
  [bladnman/do-work](https://github.com/bladnman/do-work)) — one skill queues ideas to files, a
  second drains the queue via sub-agents (plan → build → test → commit). Evaluate as a repo-owned
  skill pair.
- [Skills & skills.sh crash course](https://www.youtube.com/watch?v=rcRS8-7OgBo) (Alejandro AO) —
  covers the `npx skills` CLI we already use; watch only to check for install/lockfile flags we're
  missing in `agents/README.md`.
- [Sub-agents over one big context](https://www.youtube.com/watch?v=P60LqQg1RH8) (Leon van Zyl) —
  built-in Explore/Plan agents, `@agent` invocation, Ctrl+B background runs, wave-based parallel
  work. Decide which custom agents (code review, UI) belong in `agents/claude/` and document the
  invocation conventions.
- [Skills docs](https://code.claude.com/docs/en/skills) — audit our skills against the current
  frontmatter reference: `allowed-tools` pre-approval, argument passing, invocation control
  (user-only vs model), dynamic context injection, nested/additional skill directories.
- [simonwillison: Claude Skills](https://simonwillison.net/2025/Oct/16/claude-skills/) — background
  on why skills beat MCP here (progressive disclosure, frontmatter costs a few dozen tokens).
  Reinforces the MCP-off policy; no action beyond keeping skills small and script-backed.
- [simonwillison: OpenAI skills](https://simonwillison.net/2025/Dec/12/openai-skills/) — Codex CLI
  reads `~/.codex/skills` behind `--enable skills`. Wire our `agents/skills/` into Codex the same
  way we do for Claude/Cursor so all three CLIs share one skill set.
- [LSP / code intelligence plugins](https://code.claude.com/docs/en/discover-plugins#code-intelligence)
  — install `typescript-lsp` + `jdtls-lsp` (and the `typescript-language-server` / `jdtls` binaries,
  which the plugins do *not* install) for post-edit diagnostics and real code navigation; add to
  `machines/common/` and `verify-setup.sh`.
- Rules/skills still missing for our stack: playwright scripting (quarkus and tanstack skills are
  already installed; playwright exists only as the MCP plugin, which the MCP-off policy excludes).
- [Jeffrey Emanuel's skills portfolio](https://github.com/dicklesworthstone) —
  [jeffreys-skills.md](https://jeffreys-skills.md/) (`jsm` CLI, a rival to `npx skills`). Skim for
  skills worth vendoring; do not add a second skill manager.
- [Work efficiently on complex tasks](https://code.claude.com/docs/en/costs#work-efficiently-on-complex-tasks)
  — plan mode before implementing, Esc/`/rewind` to course-correct early, give verification targets,
  test incrementally. Fold into `agents/AGENTS.md` as working rules.
