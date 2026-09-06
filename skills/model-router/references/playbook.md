# Router playbook — details on demand

## Effort mechanics (what the keywords actually do)
Each agent file in ~/.claude/agents/ carries `effort:` (scout Sonnet low, builder/verifier Opus high, architect Fable high; values low/medium/high/xhigh/max), so effort changes automatically whenever the router changes tier. Thinking keywords in the brief then bump the budget for that one request: "think" < "think hard" < "think harder" < "ultrathink". They only matter where reasoning is the bottleneck; on lookup or transcription work they add latency and burn budget for identical output. The main session's own effort comes from settings.json (`effortLevel`, or per-model under `modelSettings`) and only the user can change it mid-session with /effort or /model. MAX_THINKING_TOKENS caps everything; leave it unset unless costs demand a ceiling.

## Checkpoint re-routing (the switch-back-and-forth rule)
The tier is decided per part and re-decided at every checkpoint (plan approved, agent returned, verdict in, new fact, user changed the ask). Down-shifts are free and expected: architect plans, builder types, scout greps, verifier checks, and the top model is idle in between. Up-shifts need evidence, but under the quality-first setting one failed verification is enough: retry builder with "think harder" only for a contained slip, otherwise the part goes to architect, and blast-radius discovery jumps straight to architect + human stop. An escalation applies to the part that earned it, not to the rest of the task — once the retry passes, the next part resumes its natural tier. Log each switch as a one-line `Re-route: a → b (reason)`.

## Domain adjustments to the base rubric
- **Content/brand work:** verification is almost always 2 (human taste). Compensate by giving the verifier a written standard (voice guide, strategy doc) so PASS/FAIL is checkable, not vibes.
- **Data analysis:** blast radius comes from *decisions made on the numbers*, not the query. A throwaway chart is scout/builder; numbers that will set a price or go to a client are architect-reviewed with the calculation re-run programmatically.
- **Debugging:** never let the tier drop below the tier of the code being debugged. A billing bug is architect even when the fix is one line.
- **Prompts/specs for other sessions:** always architect. An error in a spec is multiplied by every session that executes it.

## Brief template (what every delegated part receives)
GOAL: one sentence. CONSTRAINTS: the non-negotiables (platform facts, style rules, forbidden actions). INPUTS: exact file paths. DEFINITION OF DONE: checkable statements. EFFORT: the keyword, or "answer directly". RETURN: the compact shape you want back (findings table / diff summary / verdict). Never forward conversation history.

## Anti-patterns (each has burned real budget)
1. Architect used as a typist — top model implementing a settled plan.
2. Effort as reassurance — "ultrathink" on everything "to be safe". Escalation loses meaning and quota drains.
3. Verifier = author — self-review passes ~everything; the whole point is adversarial distance.
4. Scout dumping files — if a scout returns file contents instead of conclusions, the context saving is gone; tighten the brief.
5. Silent downgrade inside a part — finishing a hard part on a cheaper tier because it "looked almost done"; the cliff appears exactly at the hard bit. (Down-shifting *between* parts is the router working as intended.)
7. Sticky escalation — one failed retry sent the whole rest of the task to architect. Escalate the part, then come back down.
6. Routing the trivial — a one-step task routed through three agents costs 5× the direct answer.

## Weekly tune-up (2 minutes)
Look at the routing lines from the week. If architect handled >50% of parts, briefs are under-specified (ambiguity is being bought instead of written down). If verification failures cluster on one kind of task, raise that task's default tier in this playbook rather than re-deciding each time.
