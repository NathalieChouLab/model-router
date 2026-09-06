# model-router for Claude Code

A skill plus eight pinned subagents that route each **part** of a task to the right model *and* effort level, and re-route at every checkpoint while the task is running. Quality-first by default.

Claude Code cannot change its own session model mid-task (`/model` and `/effort` are user-only). This router works around that: your main session stays on the top model and does the thinking about *who should do what*; each part is handed to a subagent whose file pins both a `model:` and an `effort:`. Switching tier switches both.

## Tiers

| Agent | Model | Effort | Does |
|---|---|---|---|
| `scout` | sonnet | low | read-only lookup: grep, locate, summarize. Returns `path:line — fact`, never file dumps |
| `researcher` | sonnet | medium | read-only, web-enabled: library/API docs, versions, platform facts, marked CONFIRMED / LIKELY / UNKNOWN with sources |
| `builder` | opus | high | implements an agreed plan, runs the check that proves it |
| `tester` | opus | high | writes and runs the tests from the brief, independently of the builder |
| `writer` | opus | medium | prose from an approved outline: README, docs, changelog, UI and marketing copy |
| `verifier` | opus | high | adversarial, read-only review of someone else's change; `PASS`/`FAIL` with evidence |
| `architect` | fable | high | plans and decisions; anything with blast radius 2 (billing, auth, data, deploy) |
| `auditor` | fable | max | read-only final gate for blast radius 2: `SHIP` / `DO NOT SHIP`, with rollback check |

## How it routes

1. **Classify** the task on four axes, 0–2 each: ambiguity, blast radius, novelty, verification. Sum → scout (0–1), builder (2–4), architect (5–8). Blast radius 2 overrides everything and stops for human review.
2. **Split** mixed tasks so each part runs at its own tier: architect plans, researcher confirms external facts, tester writes tests, builder implements, writer does the prose, scout greps in parallel, verifier checks (never the author), auditor gates blast-radius-2 changes.
3. **Delegate** with a self-contained brief: goal, constraints, files, definition of done, return shape.
4. **Re-route at every checkpoint.** Plan approved → builder. Unknown cause found → architect. Builder fails verification → raise effort, then model. Retry passed → next part drops back to its natural tier. Every switch is logged as one line: `Re-route: builder → architect (cause unknown)`.
5. **Skip routing** for trivial one-step tasks. The router must never cost more than the work.

Details, domain rubrics, anti-patterns, and seven worked examples are in `skills/model-router/references/`.

## Install

```bash
git clone https://github.com/NathalieChouLab/model-router.git
cd model-router && ./install.sh
```

This copies `skills/model-router/` to `~/.claude/skills/` and the eight agents to `~/.claude/agents/`, backing up anything already there. Open a new Claude Code session and give it a non-trivial task, or type `/model-router`.

**No access to Fable?** Change `model: fable` to `model: opus` in `agents/architect.md` (the installer prints the one-liner).

## Cost-first variant

If usage matters more than retries, lower the pins and raise the thresholds. This is how the router originally shipped:

| Agent | Model | Effort |
|---|---|---|
| scout | haiku | low |
| builder | sonnet | medium |
| verifier | sonnet | medium |
| architect | opus | high |

and in `SKILL.md` use tiers scout 0–2, builder 3–5, architect 6–8, with escalation only after **two** failed verifications.

## Porting to Codex

`skills/model-router/references/codex-port-prompt.md` is a ready-to-paste prompt that asks OpenAI Codex to discover its own model/effort/sub-agent levers and build the same router with `config.toml` profiles and `AGENTS.md`.

## Requirements

Claude Code ≥ 2.1.25x (subagent frontmatter `effort:` field and per-call `model` override). Verified on 2.1.263.

## License

MIT
