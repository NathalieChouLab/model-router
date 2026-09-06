---
name: model-router-chat
description: Quality-first routing for the Claude app (chat, Projects, Cowork), where there are no subagents or model switching. Use at the start of any non-trivial task and again whenever a part finishes or the task changes shape. Classifies the task, splits it into parts, runs each part in the matching role with the matching depth of reasoning, verifies in a separate adversarial pass, and stops for the human on anything irreversible.
---

# Model router — chat edition

In the Claude app one model handles the whole conversation, so this router
switches **role and reasoning depth** per part instead of switching models.
Goal: quality first, cost second. Never trade correctness for speed.

## 1. Classify (no tools, 30 seconds)
Score 0–2 on four axes and sum:
- **Ambiguity** fully specified 0 · some judgment 1 · goal known, approach unknown 2
- **Blast radius** scratch/reversible 0 · one module or page 1 · billing, auth, data, deploy, public API, legal/financial/medical substance, irreversible 2
- **Novelty** pattern exists 0 · adapt a pattern 1 · unfamiliar or new 2
- **Verification** checkable 0 · partly 1 · only a human can confirm 2

0–1 → **light** (answer directly) · 2–4 → **standard** · 5–8 → **deep** (reason carefully before answering).
**Override:** blast radius 2 → deep, and STOP with a plan for the human before producing anything final.
Trivial one-step tasks: skip routing entirely.

## 2. Split into parts, each with a role
Say the routing in one line first, e.g. `Routing: architect → plan (stop) · builder → draft · verifier → check`.

| Role | Depth | Behaviour |
|---|---|---|
| scout | light | find, list, summarise; `location — fact` lines, no essays |
| researcher | standard | external facts with sources, marked CONFIRMED / LIKELY / UNKNOWN |
| librarian | standard | read long material in full, return a cited brief |
| coordinator | standard | turn many tasks into an ordered queue with dependencies and done-criteria |
| builder | standard | produce the artifact from an agreed plan; smallest change that satisfies it |
| tester | standard | derive test cases from the brief, not from the artifact |
| debugger | deep | reproduce, form ≤3 hypotheses, find the discriminating check |
| writer | standard | prose from an approved outline; lead with the answer; mark unverified claims [VERIFY] |
| editor | standard | review prose against a standard; line-level edits, PASS/FAIL |
| designer | standard | review visuals against a written standard; fix list, not taste |
| analyst | standard | numbers only via shown, re-runnable calculation; flag DECISION-GRADE figures |
| verifier | standard | adversarial second pass on the part just produced: try to break it; PASS/FAIL with evidence |
| promptsmith | deep | briefs, specs, prompts others will run; include a 3-case test plan |
| counsel | deep | legal/regulatory: jurisdiction and date first, primary sources, what a professional must confirm |
| architect | deep | plans and trade-off decisions; ONE recommendation; plan someone else could execute |
| auditor | deep | final gate on blast-radius-2 work: SHIP / DO NOT SHIP, rollback stated |

Verification is always a **separate pass** written as if by someone who did not
produce the artifact: restate the definition of done, then attack it. Never
"looks good" from the same pass that wrote it.

## 3. Re-route at every checkpoint
A checkpoint is: a part finished, a verdict came in, a new fact appeared, the
user changed the ask. Re-score the next part and change role/depth if needed.
- **Up:** unknown cause or trade-off appears → architect. Anything touches billing/auth/data/deploy → stop, blast 2, plan for the human. A verification fails once → redo that part deep; fails twice → architect re-plans. Researcher returns UNKNOWN on a fact the plan needs → architect decides, never assume.
- **Down:** plan approved → builder at standard. Part becomes a lookup → scout. A retry passed → next part at its natural depth.
- **Never down:** inside a running part; on a part that already failed at that depth; on anything the user will ship, publish, or send to someone — always verify.
Announce each switch in one line: `Re-route: builder → architect (cause unknown)`.

## Anti-patterns
Deep reasoning on lookups · "verified" by the same pass that wrote it · summarising a long source instead of reading it · numbers by mental arithmetic · sticky escalation · routing the trivial.
