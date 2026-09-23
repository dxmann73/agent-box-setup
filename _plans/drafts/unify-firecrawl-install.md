# Unify / re-evaluate the Firecrawl installation

- created: 2026-09-23
- priority: p3 (low) — no urgency signal in the text
- source: user, this thread
- branch: main

There is a firecrawl update, the say I need to do "npx -y firecrawl-cli@latest init --all --browser"
QUestion: Is this already part of the setup?

https://www.firecrawl.dev/blog/introducing-alexandria-series-b

## Related

- `_plans/open/2026-09-15-modular-box-setup.md` — unchecked `firecrawl-cli` and `firecrawl-login` ticks will encode whatever install this re-evaluation settles

## Observations

- Setup already splits the CLI (`npm install -g firecrawl-cli` in `machines/common/03-dev-environment.md` and `machines/vm/guest-baseline.sh`), login (`firecrawl login --browser` in `machines/vm/05-credentials.md`), and the skill (`npx skills add firecrawl/cli -g -s firecrawl -y` in `agents/README.md`). `init --all --browser` is not in the tree.
- Vendored `agents/skills/firecrawl/rules/install.md` still recommends `npx -y firecrawl-cli -y` and pins `firecrawl-cli@1.8.0`.

---

Also see `_plans/README.md` and the project `README.md` for any rules that apply.
