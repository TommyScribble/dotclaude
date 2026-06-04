---
name: explain
description: >
  Explain what was just written — what it does, why it was done this way,
  and what alternatives were possible. Use after an agent makes changes,
  before committing, or when you want to stay close to code you didn't
  write yourself. Scope to a file or function with /explain <path or name>.
---

# Explain: Code Comprehension and Alternatives

## Purpose

This skill exists to keep the developer in the driving seat when AI writes code.
It makes the reasoning behind changes explicit and surfaces the roads not taken —
so that what gets committed is understood, not just approved.

## Inputs

The user may invoke this with:

- No argument — default to current uncommitted changes (`git diff HEAD`)
- A file path — explain the current state of that file and any recent changes to it
- A function or component name — locate it, explain it in context
- A commit hash or range — explain what that commit/range did

Parse the argument from the invocation line if present.

## What to Produce

Work through the following sections in order. Do not skip any.

---

### 1. What changed (or what this does)

If scoped to current changes: read the diff and state plainly what was added, removed, or modified.
If scoped to a file or function: read it and describe what it does in plain language.

Write this as if explaining to the developer who owns the code but hasn't looked at it yet.
No jargon. No restating the code. Explain the *behaviour and intent*, not the syntax.

---

### 2. Where it fits in the architecture

Locate this code in the project's patterns:

- Is it an atom, molecule, organism, template, or page component?
- Does it involve a viewModelBuilder? If so, what does the builder provide and what does the presenter consume?
- Does it touch the API layer, a context, a hook, or shared state?
- What does it depend on, and what depends on it?

If the change crosses multiple layers, trace the full path from data source to render.

---

### 3. Key decisions made

Identify 2–4 specific decision points in the code. For each:

- **What was decided:** e.g. "the component receives X as a prop rather than fetching it directly"
- **Why:** the likely reason — architectural fit, performance, simplicity, constraints
- **What it implies:** what this decision rules out or commits to going forward

These should be the moments where an alternative approach was genuinely possible.
If a decision looks arbitrary or unclear, flag it — do not paper over it.

---

### 4. Alternatives that were possible

Always produce this section. Even if the chosen approach is clearly correct,
name the alternatives and explain why they were not chosen (or why they might still be worth considering).

Format as a list. For each alternative:

- **Approach:** what it would have looked like
- **Tradeoff:** what it gains and what it costs relative to the chosen approach
- **When it would be better:** the conditions under which this alternative would be the right call

Aim for 2–3 alternatives. At least one should be meaningfully different in structure,
not just a minor variation. Do not invent implausible alternatives — only include ones
that a reasonable developer might actually have reached for.

---

### 5. What to watch for

Flag anything that:

- Deviates from the established patterns in this codebase (ViewModel builder, atomic design, CSS Modules)
- Could cause problems under edge cases the current tests don't cover
- Is harder to reverse or change than it looks
- The developer should actively understand before committing — not just skim

If nothing warrants a flag, say so explicitly. Do not omit this section.

---

## Tone

Write for a developer who is technically capable but hasn't been in this code.
Be direct. Do not hedge. Do not congratulate the code for existing.
If something is unclear or questionable, say so clearly.

The goal is comprehension, not reassurance.