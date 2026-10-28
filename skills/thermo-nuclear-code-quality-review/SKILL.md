---
name: thermo-nuclear-code-quality-review
description: Run an extremely strict maintainability review for abstraction quality, giant files, and spaghetti-condition growth. Use for a thermo-nuclear code quality review, thermonuclear review, deep code quality audit, or especially harsh maintainability review.
disable-model-invocation: true
---

# Thermo-Nuclear Code Quality Review

An unusually strict review of implementation quality, maintainability, abstraction quality, and codebase health. The goal is not to find local cleanup opportunities — it is to find **code-judo moves**: behavior-preserving restructurings that make the implementation dramatically simpler, smaller, more direct, and more obviously correct.

Because this is a trunk-based codebase with frequent commits and no PR gate, the unit under review is the working tree plus recent commits on the current branch — not a merge request. Find the diff with `git diff`, `git diff --staged`, and `git log -p` against the last few commits. The review still applies whether or not the code has shipped; quality debt committed to trunk is exactly the debt this skill exists to catch.

## Core stance

Perform a deep code-quality audit of the current changes. Rethink how the change is structured to meaningfully improve quality without altering behavior: improve abstractions and modularity, reduce spaghetti, increase succinctness and legibility. Be ambitious — if there is a clear path to a better implementation that involves restructuring surrounding code, take it. Measure twice, cut once.

If you can **delete** complexity rather than rearrange it, push hard for that. A refactor that moves the same complexity around without reducing the number of concepts a reader must hold is a failure, not a win. Prefer the version that makes the code feel inevitable in hindsight.

## What a finding must clear

Each principle below is a distinct lens. Don't restate the same finding under several headings — pick the lens that names the root cause.

1. **Ambitious simplification.** Look for reframings that make whole branches, helpers, modes, conditionals, or layers disappear. Reframe the state model so conditionals never arise, rather than centralizing them. Don't settle for "this could be a bit cleaner" when a structural rethink is visible.

2. **File size as a smell.** Treat a change that pushes a file past ~1000 lines as a default red flag. In an atomic-design codebase the remedy is usually obvious: extract an atom/molecule/organism, a hook, a helper, or a model. Only waive this when there is a compelling structural reason *and* the resulting file is still clearly organized. Call it out explicitly when crossed.

3. **No spaghetti growth.** Be suspicious of new ad-hoc conditionals, scattered special cases, and one-off branches bolted into unrelated flows. Narrow edge-case handling dropped into the middle of an already-busy function is a design problem, not a nit. Push the logic into a dedicated helper, model, or dispatcher instead of tangling an existing path.

4. **Direct over magical.** Prefer boring, explicit, maintainable code. Be skeptical of generic mechanisms that hide simple data-shape assumptions, and of thin wrappers / identity abstractions / pass-through helpers that add indirection without buying clarity. An abstraction must earn its keep.

5. **Clean type and data boundaries.** Question unnecessary optionality, `any`, `unknown`, and cast-heavy code where a clearer typed boundary could exist. Prefer explicit typed models and shared contracts over loosely-shaped ad-hoc objects. If a branch relies on a silent fallback to paper over an unclear invariant, make the boundary explicit instead.

6. **Logic in its canonical layer.** Flag feature logic leaking into shared/general-purpose paths, and implementation details leaking through an API. Prefer existing canonical utilities over bespoke near-duplicates. Push code toward the module/service that already owns the concept rather than normalizing drift.

7. **Atomicity and orchestration.** If independent work is serialized for no reason, ask whether it should run in parallel. If related updates can leave state half-applied, push for a more atomic structure. Flag avoidable orchestration complexity that makes the implementation brittle — without over-indexing on micro-optimizations.

## Repo standards to enforce

This codebase has settled conventions. Treat violations introduced by the change as findings:

- **Page architecture** — page routes call a `viewModelBuilder` in `getServerSideProps` and pass a typed, **discriminated-union** ViewModel to a pure presenter. Flag data-fetching or orchestration leaking into the presenter, and ViewModels that use loose optionality instead of distinct success/error/notFound variants.
- **Atomic design** — components belong in `atoms / molecules / organisms / templates / pages` by composition level. Flag a component that has outgrown its level (an "atom" doing organism work) or page-specific logic embedded in a shared component.
- **Canonical layers** — singleton services come from `iocContainer`, not direct instantiation; domain logic lives in `models/`, `services/`, `search/`, `hooks/`. Flag bespoke helpers where a canonical one exists, and business logic stranded in a component.
- **Control-flow style** — replace nested-ternary value-by-discriminator mapping with a `Record<Key, V>` lookup; flatten nested `if`s with `&&`; no `Boolean()` wrapper (use `!!` or the raw truthy expression).
- **Self-documenting code** — comments are a smell; if a comment explains *what* the code does, the remedy is to rename / extract / restructure until the code reads as the comment would have.
- **Style invariants** — no semicolons, no trailing commas, no abbreviations in names or callbacks (`item` not `i`, `event` not `e`). These are filewatcher/lint concerns, so only raise them if the *structure* of the change institutionalizes them; don't pad the review with formatting nits.

## Primary questions

- Is there a code-judo move that makes this dramatically simpler, or reframes it so fewer concepts and branches are needed?
- Does this improve or worsen the local architecture? Did a cohesive module become more coupled, more stateful, or harder to scan?
- Is this logic in the right file and layer? Did a detail leak across a boundary?
- Did the change add branching where a better abstraction (typed model, dispatcher, state machine) should exist? Do repeated conditionals signal a missing model?
- Is each abstraction earning its keep, or is it a wrapper / cast / optional that obscures the real contract?
- Did the change enlarge a file or component past a healthy boundary?
- Is the orchestration more sequential or less atomic than it needs to be?

## Preferred remedies

Prefer, in rough order of value:

- Delete a layer of indirection rather than polishing it.
- Reframe the state model so conditionals disappear instead of getting centralized.
- Turn special-case logic into a simpler default flow with fewer exceptions.
- Replace condition chains with a typed model, `Record` lookup, or explicit dispatcher.
- Move the logic to the module/layer/package that already owns the concept; reuse the canonical helper instead of a near-duplicate.
- Make a type boundary explicit so the control flow simplifies.
- Extract a pure helper, hook, or subcomponent; split a large file into focused modules.
- Separate orchestration from business logic; collapse duplicate branches into one flow.
- Parallelize independent work or restructure related updates to be atomic when that also simplifies the code.

Don't settle for "maybe rename this" when the real issue is structural, and don't settle for a cleaner version of the same messy idea when a much simpler idea is plausible.

## Bar to pass

Do not pass the change merely because it works. The following are presumptive blockers unless clearly justified:

- A plausible code-judo move would delete the complexity, but the change preserves it.
- The change pushes a file from under ~1000 lines to over it without a strong, stated reason.
- It adds ad-hoc branching that tangles an existing flow.
- It scatters feature-specific checks across shared code.
- It adds an unnecessary abstraction, wrapper, or cast-heavy contract that makes the design more indirect.
- It duplicates an existing helper or puts logic in the wrong layer when a canonical home exists.
- It misses an obvious decomposition that would materially improve maintainability.

If any hold, leave explicit, actionable findings and push for the cleaner decomposition.

## Output

Prioritize findings:

1. Structural code-quality regressions
2. Missed opportunities for dramatic simplification / code-judo restructuring
3. Spaghetti / branching-complexity increases
4. Boundary / abstraction / type-contract problems
5. File-size and decomposition concerns
6. Modularity, legibility, and maintainability concerns

Be direct and demanding about quality. Prefer a small number of high-conviction findings over a long list of cosmetic notes — don't flood the review with low-value nits when larger structural issues exist.
