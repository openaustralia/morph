# Domain docs

How the engineering skills should consume this repo's domain documentation when
exploring the codebase.

## Before exploring, read these

- **`CONTEXT.md`** at the repo root. This exists. It is the glossary of
  morph.io's domain terms, and it is opinionated about which words to avoid.
- **`docs/adr/`**, reading the ADRs that touch the area you are about to work
  in. This does not exist yet.

If a file is not there, **proceed silently**. Do not flag its absence and do not
suggest creating it upfront. The `/domain-modeling`
skill (reached via `/grill-with-docs` and `/improve-codebase-architecture`)
creates them lazily when terms or decisions actually get resolved.

`AGENTS.md` at the repo root is the standing guidance for this repository and
is separate from all of this. Read it regardless.

## Layout

This is a **single-context** repo. One Rails application, one `Gemfile`, no
workspaces:

```
/
├── AGENTS.md          ← standing agent guidance (exists)
├── CONTEXT.md         ← glossary of domain terms (exists)
├── docs/
│   ├── adr/           ← not created yet
│   │   ├── 0001-some-decision.md
│   │   └── 0002-another-decision.md
│   └── agents/        ← this directory
├── app/
│   └── lib/morph/     ← the scraping, Docker and SQLite domain logic
└── lib/
```

If morph.io ever splits into separately deployed packages, the multi-context
form applies instead: a root `CONTEXT-MAP.md` pointing at one `CONTEXT.md` per
context, with context-scoped ADRs beside each.

Note the repo already has a `doc/` directory holding
[`doc/UPGRADE_PATH.md`](../../doc/UPGRADE_PATH.md), which is the Rails
convention and is not the same place. Agent-facing docs and ADRs go under
`docs/`.

## Use the glossary's vocabulary

When your output names a domain concept, whether in an issue title, a refactor
proposal, a hypothesis or a test name, use the term as defined in `CONTEXT.md`.
Do not drift to synonyms the glossary explicitly avoids.

If the concept you need is not in the glossary yet, that is a signal. Either
you are inventing language the project does not use, in which case reconsider,
or there is a real gap, which is worth noting for `/domain-modeling`.

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than
silently overriding it:

> _Contradicts ADR-0007 (event-sourced orders), but worth reopening because..._
