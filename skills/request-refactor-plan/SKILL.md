---
name: request-refactor-plan
description: Create a detailed refactor plan broken into tiny trunk-based commits via a structured user interview, then save it as a markdown file. Use when the user wants to plan a refactor, create a refactoring RFC, or break a refactor into safe incremental steps.
---

This skill produces a refactor plan through a structured interview, then saves it as a markdown file. It assumes trunk-based development: small, frequent commits straight to `master`, each leaving the codebase green. There are no PRs or issues — the deliverable is a plan file the user (or a future agent) works through commit by commit.

Follow the steps below in order. Skip a step only if the user has already supplied the information.

## Step 1 — Problem Description

Ask the user for a detailed description of the problem they want to solve and any ideas they already have for a solution. If they've already described it, acknowledge what you have and only probe the gaps.

## Step 2 — Codebase Exploration

Explore the repo to verify their assertions and understand the current state. Answer what you can yourself before asking. Map the change onto the codebase's architecture:

- Which page, `viewModelBuilder`, and presenter are involved?
- Which atoms/molecules/organisms/templates are touched, and what's the component hierarchy?
- Which API domains, types, contexts, services, hooks, or models are in play?
- Are any singletons involved (imported from `iocContainer.js`)?

Summarise what you found briefly. Flag anything that contradicts the user's framing.

## Step 3 — Alternatives

Ask whether they've considered other approaches, and present alternatives of your own. Give a recommendation rather than an exhaustive survey.

## Step 4 — Implementation Interview

Interview the user about the implementation. Be thorough. Resolve every ambiguity — edge cases, error/empty/loading states, responsive behaviour, interactions, data flow, and scope boundaries. Ask in batches of 3–5; don't ask what the codebase can answer. Continue until no branch is unresolved.

## Step 5 — Scope

Hammer out exactly what will and will not change. Be explicit about out-of-scope items so the plan doesn't sprawl.

## Step 6 — Test Coverage

Check the affected area for existing test coverage. Note prior art (similar tests in the codebase) the plan can follow. If coverage is thin, ask the user how they want to handle it. Remember the project conventions: co-located `*.test.tsx` for components, `pages.test/` for page-level integration, the `setup()` + `test/data/` fixture pattern, and verb-led test names asserting external behaviour over implementation.

## Step 7 — Commit Plan

Break the implementation into a sequence of the tiniest commits possible. Apply Martin Fowler's advice: "make each refactoring step as small as possible, so that you can always see the program working." Because this is trunk-based, every commit must:

- Leave the codebase building, type-checking, and passing tests (green to push to `master`)
- Be independently revertable without breaking a later commit
- Follow the project's TDD loop where behaviour changes — a failing test first (`/tdd`), then minimal code to green
- Carry a Conventional Commits one-line subject (no scope, no body) describing the change, not the process

Order commits by implementation sequence. Pure structural moves (rename, extract, relocate) should be separate from behaviour changes.

## Step 8 — Save the Plan

Save the plan as a markdown file **outside the code repo** — planning docs don't belong in the codebase. Save it to `~/Documents/Obsidian Vault/claude-docs/<kebab-case-subject>.md` (e.g. `area-map-responsive-refactor.md`; quote the path — it has a space). Use this template:

```markdown
# [Refactor Title]

**Date:** [today's date, YYYY-MM-DD]
**Area:** `path/to/primary/module/`
**Estimated effort:** [rough estimate]

## Problem
The problem from the developer's perspective, with concrete detail. Use tables or numbered lists to capture coupling points, breakpoints, or scattered usages where it aids clarity.

## Solution
The chosen approach and why, from the developer's perspective.

## Commits
A long, detailed, ordered list of the tiniest commits possible. Write each in plain English. For each commit state the intended one-line Conventional Commits subject and, where behaviour changes, the failing test that drives it. Every commit must leave the codebase green and independently revertable.

## Decision Document
The implementation decisions that were made:

- Modules built/modified and how their interfaces change
- Technical clarifications from the developer
- Architectural decisions (ViewModel/presenter boundaries, atomic level, context/service ownership)
- Schema changes, API contracts, specific interactions

Do NOT include specific code snippets — they go stale fast. Referencing module paths is fine.

## Testing Decisions
- What makes a good test here (external behaviour, not implementation detail)
- Which modules will be tested and at what level (component vs `pages.test/` integration)
- Prior art — similar existing tests to follow

## Out of Scope
What this refactor explicitly will not touch.

## Risks
A table of risks with likelihood, impact, and mitigation.

## Context (optional)
How this refactor came up and any further notes.
```

## Step 9 — Review

After writing the file, ask the user: "Does this match your understanding? Anything to add, remove, or reorder?" Incorporate feedback, then confirm the plan is final and remind them they can work through it commit by commit with `/tdd` and `/commit`.
