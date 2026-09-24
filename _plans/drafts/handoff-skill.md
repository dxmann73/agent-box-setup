# Handoff skill: persist conversation results and chat-stated rules before a clear

- created: 2026-09-24
- priority: p2 (medium) — recurring lost context in daily `dave.macros` use, no deadline
- source: BB thread `thr_rr8kvjjnp3` (clackworks.agents, agent-ambassador planning), 2026-09-24
- branch: main

> I totally agree about the handoff skill; do add a plan for this.

> Your observation is a thing that needs to be baked into the system somehow, that's a thing we
> need to address, I'm leaning towards your suggestion here, also agree about the eval.

Context from the same thread (the observation referred to): the human clears context often and
treats a clear as the start of a new conversation, passing work on through artifacts. In
`dave.macros` (`thr_72yrpmmyr3`) the human stated a standing rule in chat on 2026-09-13 ("As
stated in the AgentsMD, always assume the defaults is a morning walk, an evening walk, a smoothie
and a default breakfast."). The smoothie was not in `AGENTS.md`; the agent replied "Got it.
Defaults confirmed" without correcting the claim or persisting the rule. The next clears dropped
it, and on 2026-09-15 the human had to ask "How did you miss that again?". Suggestion made: a
handoff skill that, before a clear, writes decisions, chat-stated standing rules, state, and the
next step into durable artifacts; and agents must persist chat-stated standing rules or correct a
false "as stated in X" claim.

## Related

- `~/projects/clackworks.agents/_plans/next/agent-ambassador.md` — ambassador plan that found this
  failure and records the evidence; it decides clear vs compact vs handoff.
- `~/projects/evals/_plans/drafts/conversation-failure-evals.md` — eval cases for the same failure.

## Observations

- No handoff, resume, or session skill exists in `agents/skills/` yet.
- `_plans/open/2026-09-15-modular-box-setup.md` is the active work in this repository.

---

Also see `_plans/README.md` and the project `README.md` for any rules that apply.
