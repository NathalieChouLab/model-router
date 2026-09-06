# model-router-claude

A skill plus eighteen pinned subagents that route each **part** of a task to the right model *and* effort level, and re-route at every checkpoint while the task is running. Quality-first by default.

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
| `designer` | opus | high | read-only UI/visual review against a written standard; renders the page, returns a fix list |
| `debugger` | opus | high | reproduces, bisects, instruments to find a confirmed cause; hands off the fix |
| `analyst` | opus | high | numbers computed by shown, re-runnable code; flags DECISION-GRADE figures |
| `librarian` | sonnet | medium | large-context reader: digests long specs, transcripts, logs into a cited brief |
| `coordinator` | opus | high | read-only: turns a multi-task request into an ordered queue with tiers, dependencies, done-criteria |
| `promptsmith` | fable | high | read-only: writes briefs, specs, system prompts, and agent files other agents will execute |
| `editor` | opus | medium | read-only prose review against a voice guide or standard; never the writer |
| `counsel` | fable | high | read-only legal/regulatory analysis: jurisdiction, primary sources, what a professional must confirm |
| `operator` | opus | high | system administration and ops: read-only diagnosis first, minimal change, every command reported |
| `monitor` | haiku | low | read-only log/health/status checks; reports only what changed or looks wrong |

## How it routes

1. **Classify** the task on four axes, 0–2 each: ambiguity, blast radius, novelty, verification. Sum → scout (0–1), builder (2–4), architect (5–8). Blast radius 2 overrides everything and stops for human review.
2. **Split** mixed tasks so each part runs at its own tier: architect plans, researcher confirms external facts, librarian digests long inputs, tester writes tests, builder implements, debugger finds causes, writer does the prose, designer reviews UI, analyst produces numbers, scout greps in parallel, verifier checks (never the author), auditor gates blast-radius-2 changes.
3. **Delegate** with a self-contained brief: goal, constraints, files, definition of done, return shape.
4. **Re-route at every checkpoint.** Plan approved → builder. Unknown cause found → architect. Builder fails verification → raise effort, then model. Retry passed → next part drops back to its natural tier. Every switch is logged as one line: `Re-route: builder → architect (cause unknown)`.
5. **Skip routing** for trivial one-step tasks. The router must never cost more than the work.

Details, domain rubrics, anti-patterns, and seven worked examples are in `skills/model-router/references/`.

## Install

```bash
git clone https://github.com/NathalieChouLab/model-router-claude.git
cd model-router && ./install.sh
```

This copies `skills/model-router/` to `~/.claude/skills/` and the eighteen agents to `~/.claude/agents/`, backing up anything already there. Open a new Claude Code session and give it a non-trivial task, or type `/model-router`.

### Profiles: pick one for your plan

```bash
PROFILE=quality ./install.sh   # default — Max, Team Premium, Enterprise, API
PROFILE=pro ./install.sh       # Claude Pro
PROFILE=cost ./install.sh      # usage-first on any plan
```

| Agent | quality | pro | cost |
|---|---|---|---|
| scout | sonnet · low | haiku · low | haiku · low |
| researcher | sonnet · medium | sonnet · medium | haiku · medium |
| builder | opus · high | sonnet · high | sonnet · medium |
| tester | opus · high | sonnet · high | sonnet · medium |
| writer | opus · medium | sonnet · medium | sonnet · low |
| verifier | opus · high | sonnet · high | sonnet · medium |
| architect | fable · high | opus · high | opus · high |
| auditor | fable · max | opus · xhigh | opus · high |
| designer | opus · high | sonnet · high | sonnet · medium |
| debugger | opus · high | opus · high | sonnet · high |
| analyst | opus · high | sonnet · high | sonnet · medium |
| librarian | sonnet · medium | sonnet · medium | haiku · medium |
| coordinator | opus · high | opus · high | sonnet · high |
| promptsmith | fable · high | opus · high | opus · high |
| editor | opus · medium | sonnet · medium | sonnet · low |
| counsel | fable · high | opus · high | opus · high |
| operator | opus · high | sonnet · high | sonnet · high |
| monitor | haiku · low | haiku · low | haiku · low |

**Why the `pro` profile looks like this.** On Claude Pro the session default is Sonnet 5, Opus draws on the same 5-hour usage window, and Fable can bill to usage credits rather than the plan's included limits (see [Claude Code model configuration](https://code.claude.com/docs/en/model-config)). So `pro` keeps the mechanical tiers on Sonnet at high effort, which is where most tokens go, and spends Opus only on the two tiers where judgment is expensive to get wrong: `architect` and `auditor`. The routing rules are identical; only the pins change. If you later buy usage credits or move to Max, re-run with `PROFILE=quality`.

The tables live in `profiles/*.tsv` (agent, model, effort per line) — edit or add your own and install with `PROFILE=<name>`.

## Cost-first variant

`PROFILE=cost` lowers the pins. To also loosen the rules, edit `SKILL.md`: tiers scout 0–2, builder 3–5, architect 6–8, and escalate only after **two** failed verifications.

## Claude app (chat) edition

`claude-app/model-router-chat.zip` is an uploadable skill for the chat side of the Claude app, where subagents and model switching do not exist: it routes roles and reasoning depth instead. See `claude-app/README.md`.

## Porting to Codex

`skills/model-router/references/codex-port-prompt.md` is a ready-to-paste prompt that asks OpenAI Codex to discover its own model/effort/sub-agent levers and build the same router with `config.toml` profiles and `AGENTS.md`.

## Cloud sessions (Claude Code web, mobile, `claude --cloud`)

Cloud sessions run in a fresh sandbox and never see your machine's `~/.claude`. You do **not** need to commit the router into every repo: paste `cloud/setup-script.sh` into your cloud environment's **Setup script** field at [claude.ai/code](https://claude.ai/code) (environment settings). It runs once per environment, installs the router into the sandbox's `~/.claude` from this repo, and the snapshot is cached, so every later session on any repo starts with the 22 agents ready. Pick the pins with an environment variable: `MODEL_ROUTER_PROFILE=quality|pro|cost` (default quality).

Per-repo install is still available for repos shared with people who don't use the setup script:

```bash
PROJECT_DIR=/path/to/your/repo ./install.sh   # writes .claude/ and a CLAUDE.md note; commit and push
```

## Requirements

Claude Code ≥ 2.1.25x (subagent frontmatter `effort:` field and per-call `model` override). Verified on 2.1.263.

## License

MIT
