# Worked routing examples

Real tasks, scored and routed. Read this when a classification feels ambiguous.

## 1. "Fix the export bug — the button does nothing on iPhone"
Ambiguity 2 (cause unknown) · Blast 1 (one feature, but it's the paid feature → treat as 2 if export is the paywall boundary) · Novelty 2 (unseen codebase) · Verification 1 (device test needed) = 6–7 → ARCHITECT.
Routing: `architect(ultrathink) → root-cause + plan (STOP) · builder → patch handler · verifier → run probe checks · human → iPhone test`.
Why not builder-first: six plausible causes existed (codec, gesture, canvas, delivery, throttling, permissions); a mid model picks one and "fixes" it.

## 2. "Update the pricing page copy: remove watermarked export from the Free card"
Ambiguity 0 · Blast 1 (public marketing page) · Novelty 0 · Verification 0 (visual diff) = 1 → but blast 1 on public copy → BUILDER, default effort. No architect needed: the decision was already made; this is transcription.
Routing: `builder → edit pricing.html · scout → grep for other stale "watermark" mentions`.

## 3. "Re-wire the RevenueCat offering to the new Stripe prices"
Blast 2 (billing) → ARCHITECT regardless of how mechanical it looks.
Routing: `architect(think hard) → exact click-path checklist + what to verify after (STOP; human executes in dashboard)`. Agents never touch billing config autonomously.

## 4. "Where does the effect engine drive time from?"
Pure reconnaissance = 0–1 → SCOUT, no extended reasoning.
Brief: "Grep for performance.now, requestAnimationFrame, animation-duration under src/. Return file:line + one line each. If the time model is unclear from matches alone, say 'needs deeper read' and stop."

## 5. "Write the marketing plan for launch"
Ambiguity 2 · Blast 1 (public positioning) · Novelty 1 · Verification 2 (only human judgment) = 6 → ARCHITECT(think hard) for strategy + positioning; BUILDER for deriving per-channel copy from the approved strategy; VERIFIER checks copy against the strategy doc, not against taste.

## 6. "Add a test for pickBitrate()"
0 across the board → trivial; skip routing, just write it. The router must never cost more than the work.

## 7. Mid-task re-routing: "Add CSV export to the reports page"
Initial score: Ambiguity 1 · Blast 1 · Novelty 1 · Verification 1 = 4 → BUILDER.
- Builder starts, reports the export helper reads from a cached query whose invalidation it can't explain → `Re-route: builder → architect (unknown cache semantics)`. Architect(high) reads the cache layer, writes a two-step plan.
- Plan approved → `Re-route: architect → builder (plan approved)`. Builder implements step 1; scout in parallel greps for other callers of the cache (low effort).
- Verifier FAILs on an empty-dataset edge case → builder retried with "think hard about the edge cases" (effort step, same model). Passes.
- Step 2 is a copy change on the page → BUILDER default effort; verifier at default. Done.
Net: the top model was used for one part of six. Without checkpoints the whole task would either have run on architect (waste) or stayed on builder past the cache bug (rewrite).