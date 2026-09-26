# Merge agent-box-setup, dave.box-setup, and infra into one Ansible-driven repository

- created: 2026-09-26
- priority: p2 (medium) — user stated "Priority is P2"
- branch: main

Restructure the agent box setup, Dave box setup, and infra repos in a way that we can discuss it, but the goal would be Ansible does most of the work. This should make this whole setup a lot easier. Maybe there are parts that have to be done by Terraform. This could also be a discussion. The secrets should live in a vault, maybe HashiCorp's vault or some safe solution so that I can actually check in everything and have the repo public. Because right now agent box setup is public, Dave box setup is not, and this is kind of a weird situation. Also the infra thing contains stuff which is actually part of infrastructure. Tailscale is part of the agent box setup. So this is all intermingled, and I think it should live in one repo. We need to look at this. Priority is P2.

## Related

- `_plans/open/move-bb-projects-to-agent-vm.md` — adds a `git-identity` module that copies `.gitconfig` from `dave.box-setup`; a merge changes where that file comes from.
- `_plans/drafts/rename-terms.md` — renames `overlay`; the overlay concept disappears if the repos merge.
- `_plans/done/2026-09-15-modular-box-setup.md` — defines the current module catalog that an Ansible layout would replace or map onto.

## Observations

- No Ansible, Terraform, or Vault files exist in this repository today; the only matches are unrelated skill text and Bitwarden recipes.
- `dave.box-setup` tracks Windows and Office license keys under `windows-box/licenses/`; these need a vault home before anything goes public.
- `gh repo view` reported `agent-box-setup` as `PUBLIC` on 2026-09-26.
- `AGENTS.md` now carries a credential grep check (uncommitted), which a public merged repository would depend on.

---

Also see `_plans/README.md` and the project `README.md` for any rules that apply.
