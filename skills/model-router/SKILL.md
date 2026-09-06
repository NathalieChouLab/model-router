---
name: model-router
description: Project-agnostic routing of work to the right model tier and effort level, re-decided at every checkpoint of a task. Use at the start of any non-trivial task (coding, debugging, architecture, content, research) and again whenever a part finishes, a verdict comes in, or the task changes shape mid-way — shift down when work becomes mechanical, shift up on evidence. Classifies the task, picks the strongest tier the part warrants (quality-first), delegates to a model-pinned subagent, verifies, and escalates on failure. Install once at ~/.claude/ and it applies to every repo.
---

# Model router

Goal: **quality first, cost second.** Every tier runs a model strong enough
that its output rarely needs a retry; the cheaper tiers exist to keep the main
context clean and the top model focused, not to save money at the risk of a
wrong cut. Never trade correctness for cost. (To flip back to cost-first, lower
the pins in `~/.claude/agents/*.md` and raise the thresholds below.)

## Step 1 — classify the task (30 seconds, no tools)

Score the task on four axes, 0–2 each:

| Axis | 0 | 1 | 2 |
|---|---|---|---|
| **Ambiguity** | fully specified | some judgment | goal known, approach unknown |
| **Blast radius** | scratch / reversible | one module | billing, auth, data, deploy, public API, irreversible |
| **Novelty** | pattern exists in repo | adapt a pattern | unfamiliar code or new architecture |
| **Verification** | tests/lint prove it | partially testable | only human review can confirm |

Sum → tier:

- **0–1 → SCOUT tier (Sonnet, low effort).** Exploration, grep, summarizing
  logs, renames, formatting, boilerplate, reading docs.
- **2–4 → BUILDER tier (Opus, high effort).** Implementing an agreed plan, tests, docs,
  refactors covered by tests, UI copy, well-specified features.
- **5–8 → ARCHITECT tier (Fable 5.1, high effort).** Investigating unfamiliar code to produce
  a plan, architecture and trade-off decisions, root-causing a bug with unknown
  cause, anything touching billing/auth/security/deletion, writing specs or
  prompts other sessions will execute.

**Hard overrides (ignore the score):** blast radius = 2 → ARCHITECT always.
User says "just do it quickly" on a reversible task → drop one tier.
Legal/financial/medical substance → ARCHITECT.

## Step 2 — split before routing

Most real tasks are mixed. Split them so each part runs at its own tier:

```
investigate + plan      → ARCHITECT   (stop, present plan, wait if blast radius ≥ 1)
external facts / docs   → RESEARCHER  (library APIs, versions, platform behaviour; sourced)
find/grep/summarize     → SCOUT       (run in parallel, results only, keeps main context clean)
write the tests         → TESTER      (from the brief, not the implementation; before or beside the builder)
implement the plan      → BUILDER
prose: docs, copy, README → WRITER    (from an approved outline; never decides positioning)
verify                  → VERIFIER    (never the same agent that wrote the code)
final gate on a         → AUDITOR     (only if blast radius = 2; SHIP / DO NOT SHIP)
blast-radius-2 change
cause of a failure      → DEBUGGER    (reproduce, bisect, instrument; hands cause + repro to architect/builder)
UI / visual review      → DESIGNER    (renders the page, checks against a written standard)
numbers people act on   → ANALYST     (code-computed, re-runnable; DECISION-GRADE figures go to auditor)
long material to digest → LIBRARIAN   (reads it all once, returns a cited brief; keeps it out of main context)
many tasks handed over  → COORDINATOR (ordered queue with tiers, dependencies, done-criteria; main session executes top-down)
briefs / specs / prompts for other agents → PROMPTSMITH (always top tier: errors multiply per run)
prose review            → EDITOR      (against a voice guide; never the writer)
legal / regulatory substance → COUNSEL (jurisdiction, primary sources, what a professional must confirm)
system / ops / deploy work → OPERATOR  (read-only diagnosis first; blast radius 2 stops for the human)
logs, health, status checks → MONITOR  (reports only what changed or looks wrong)
```

## Step 3 — delegate to the pinned subagents

Use the Agent tool with the matching subagent (they live in `~/.claude/agents/`
and each pins its model):

- `scout` — read-only, Sonnet at low effort
- `researcher` — read-only, Sonnet at medium effort, web-enabled, sourced facts
- `builder` — Opus, edits + runs checks
- `tester` — Opus at high effort, writes and runs tests independently of the builder
- `writer` — Opus at medium effort, prose from an approved outline
- `verifier` — Opus, read-only, adversarial
- `architect` — Fable 5.1, plans and decisions
- `auditor` — Fable 5.1 at maximum effort, read-only final gate for blast radius 2
- `designer` — Opus, read-only visual/UX review against a standard
- `debugger` — Opus at high effort, may add temporary instrumentation to find a cause
- `analyst` — Opus at high effort, numbers computed by shown code
- `librarian` — Sonnet at medium effort, large-context reader returning cited briefs
- `coordinator` — Opus, read-only, turns a multi-task request into an ordered queue
- `promptsmith` — Fable 5.1, read-only, writes briefs/specs/prompts other agents execute
- `editor` — Opus at medium effort, read-only prose review against a standard
- `counsel` — Fable 5.1, read-only legal/regulatory analysis with primary sources
- `operator` — Opus, system administration and ops with read-only diagnosis first
- `monitor` — Sonnet at low effort, read-only log/health/status checks

Each agent file pins **both** a model and an effort level, so switching tier
switches effort automatically:

| Agent | Model | Effort | Bump within tier by adding to the brief |
|---|---|---|---|
| `scout` | sonnet | low | nothing — never bump a scout |
| `researcher` | sonnet | medium | "think hard" only when sources conflict |
| `builder` | opus | high | "think harder" on concurrency, migrations, edge cases |
| `tester` | opus | high | "think harder" for concurrency or security test cases |
| `writer` | opus | medium | "think hard" for positioning-sensitive copy |
| `verifier` | opus | high | "think harder" when the change is subtle |
| `architect` | fable | high | "ultrathink" for irreversible / unknown-cause work |
| `auditor` | fable | max | already at maximum — never bump; split the change instead |
| `designer` | opus | high | "think hard" when the standard is thin |
| `debugger` | opus | high | "ultrathink" for intermittent or concurrency bugs |
| `analyst` | opus | high | "think harder" for forecasts or multi-step derivations |
| `librarian` | sonnet | medium | nothing — reading is the work |
| `coordinator` | opus | high | "think hard" when tasks share files or tiers conflict |
| `promptsmith` | fable | high | "ultrathink" for prompts that many sessions will run |
| `editor` | opus | medium | nothing — the standard does the work |
| `counsel` | fable | high | "ultrathink" for multi-jurisdiction or high-stakes questions |
| `operator` | opus | high | "think hard" before any state-changing command |
| `monitor` | sonnet | low | nothing — never bump a monitor |

The table is the `quality` profile. On Claude Pro install with `PROFILE=pro`
(Sonnet for the mechanical tiers, Opus for architect and auditor); the routing
rules below do not change, only the pins.

One-off override without editing the files: the Agent tool's `model` parameter
beats the frontmatter (e.g. run `builder` with `model: fable` for a part that is
specified but unusually delicate).

Give each a **self-contained brief**: goal, constraints, files, definition of
done. Do not forward the whole conversation. Ask for a compact result
(findings, diff summary, verdict) — not file dumps.

State the routing in one line before starting, e.g.
`Routing: architect(ultrathink) → plan (stop for review) · builder → implement · verifier → check`.

## Step 3b — effort follows the tier

Model picks the ceiling; effort decides how much of it is used. Effort is now
baked into each agent file (table above), so you normally say nothing. Bump it
with a keyword only when reasoning is the bottleneck for *that part*:

- BUILDER on tricky-but-specified work (concurrency, migrations, edge-case tests) → "think harder".
- ARCHITECT on blast radius 2 or unknown-cause debugging → "ultrathink".
- SCOUT → never. High effort on lookup work is pure waste.

## Step 4 — re-route at every checkpoint (mid-task switching)

Tiers belong to **parts**, not to the task. A checkpoint is any point where a
part ends or its shape changes: a plan gets approved, a subagent returns, a
verifier gives a verdict, a new fact appears, the user changes the ask. At
each checkpoint re-score the *next* part and switch tier if the score moved.
Switching down is normal and expected; switching up is triggered by evidence.

**Shift UP when:**
- A part reveals unknown cause, unfamiliar architecture, or a trade-off → next part is ARCHITECT.
- Anyone finds the change touches billing/auth/data/deploy → stop, blast radius 2, ARCHITECT, wait for the human.
- Scout says "can't tell without reading deeply" → promote that part to BUILDER.
- Builder fails verification **once** → if the failure is a contained slip, retry BUILDER with "think harder"; if it hints the plan or the cause is off, go straight to ARCHITECT (Fable). Quality-first means one failure is enough evidence.
- Builder fails verification **twice** → ARCHITECT, no exceptions.
- Verifier flags a BLOCKER it can't explain → ARCHITECT root-causes before anyone patches.
- Researcher returns UNKNOWN on a fact the plan depends on → ARCHITECT decides how to proceed without it; never let a builder assume.
- Auditor says DO NOT SHIP → back to ARCHITECT with the findings; the builder does not patch an audit failure directly.
- Builder or verifier hits a failure with no obvious cause → DEBUGGER first; ARCHITECT plans the fix from the debugger's confirmed cause.
- Analyst marks a figure DECISION-GRADE → AUDITOR before anyone acts on it.
- Monitor reports an anomaly → OPERATOR for system state, DEBUGGER for a failing behaviour, AUDITOR for anything security- or billing-shaped. The monitor itself never diagnoses.
- Operator hits production, credentials, DNS, or a remote host → blast radius 2: stop, write the command list, human executes.

**Shift DOWN when:**
- The plan is approved → implementation goes to BUILDER, not the architect.
- A part becomes a lookup, rename, grep, or summary → SCOUT, in parallel.
- A retry passed → the *next* part resumes its own natural tier; the escalation does not stick to the whole task.
- Verification is now mechanical (tests exist) → VERIFIER at default effort.
- The remaining work is prose (docs, changelog, copy) → WRITER, with the verifier checking claims against code.
- A UI part is built and testable → DESIGNER review in parallel with the verifier.
- The input is long material (spec, transcript, big log) → LIBRARIAN reads it once; everyone else works from the brief.
- The user hands over several tasks at once → COORDINATOR builds the queue first; then each item routes on its own score.
- Prose is written → EDITOR reviews it, never the writer.

**Never shift down:**
- Inside a part that is still running — finish it at the tier it started on.
- Below the tier of the code being debugged (a billing bug stays ARCHITECT even for a one-line fix).
- On anything the user will ship, publish, or send to another person — quality-first means verify with the Opus verifier even when tests pass.
- On a part that has already failed once at that tier.

Announce every switch in one line so the trail is auditable:
`Re-route: builder → architect (cause unknown after 2 failed patches)` or
`Re-route: architect → builder (plan approved)`. If nothing changed, say nothing.

**What this session cannot do:** Claude cannot change the *main* session's
model or effort — `/model` and `/effort` are user-only. The main session stays
on the top model and does the routing; the switching happens by handing each
part to the pinned agents above. Do not suggest moving the main session to a
cheaper model; the user has chosen quality-first.

## Step 5 — build or answer

Only after routing is stated. If the task is trivial (score 0–1 and takes one
step), skip delegation and just do it — the router should never cost more than
the work it routes.

## When in doubt
Ambiguous classification → read `references/examples.md` (six worked routings).
Domain-specific rubrics, the brief template, effort mechanics, and anti-patterns →
`references/playbook.md`. Read them on demand; do not load them for trivial tasks.

## What this saves — and what it doesn't

Model choice doesn't shrink token counts; it changes the **weight** of each
token against usage limits and the **odds of a retry**. The savings come from:
(1) top-tier tokens only where judgment is required; (2) scouts keeping
exploration out of the main context; (3) fewer rewrites because plans are
reviewed before code is written. The single biggest waste is a cheap model
confidently taking a wrong architectural cut — which is why blast radius
overrides everything.
