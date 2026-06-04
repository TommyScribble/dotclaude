---
name: scope-ticket
description: >
  Turn a vague ticket into a fully scoped implementation plan with checkboxed tasks.
  Use when starting work on a ticket, when user says "scope this ticket", "plan this ticket",
  or shares a ticket description/screenshot they want to break down.
---

# Scope Ticket

Turn a vague ticket into a structured, actionable implementation plan. Follow the phases below in order. Do not skip phases, but keep each phase focused — move on once you have enough to proceed.

## Phase 1 — Gather Context

Ask the user for everything they have about the ticket:

- Ticket description / acceptance criteria
- Design screenshots or mockups (ask them to share if not provided)
- Any constraints, deadlines, or dependencies they already know about
- Which page or feature area this relates to

If the user has already provided some of this, acknowledge it and only ask for what's missing. Don't repeat back what they've given you — just identify gaps.

## Phase 2 — Explore the Codebase

Before asking the user questions, answer what you can yourself:

- Find the relevant page component, viewModelBuilder, and presenter
- Identify existing components that could be reused or need modification
- Check for existing test coverage in the affected area
- Look at related types, API calls, and data flow
- Note the component hierarchy (atoms/molecules/organisms) involved

Summarise what you found briefly. Flag anything surprising or that contradicts the ticket.

## Phase 3 — Grill the User

Now interview the user to resolve every ambiguity. Channel the grill-me approach — be relentless but efficient. Focus on:

- **Edge cases** — empty states, error states, loading states, long content, missing data
- **Responsive behaviour** — what changes at mobile/tablet/desktop? Does the design show all breakpoints?
- **Interactions** — hover, focus, click, keyboard navigation, transitions
- **Data** — where does it come from? Is it already available or does it need a new API call?
- **Acceptance criteria gaps** — what does "done" look like that the ticket doesn't spell out?
- **Scope boundaries** — what's explicitly NOT part of this ticket?

Ask questions in batches of 3-5. Don't ask things you already answered in Phase 2. If a question can be answered by checking the codebase, check instead of asking.

Continue until there are no unresolved branches. When you think you're done, ask: "Is there anything else about this ticket that feels unclear or that I haven't covered?"

## Phase 4 — Produce the Plan

Write the plan to a file. Ask the user where they'd like it saved — suggest a sensible default based on the ticket name.

The plan must follow this structure:

```markdown
# [Ticket Title]

## Summary
One paragraph describing what this ticket delivers and why.

## Scope
What's in scope and what's explicitly out of scope.

## Affected Areas
- Components, pages, and files that will be created or modified
- Note any new components that need creating vs existing ones being extended

## Tasks

- [ ] **Task name** — brief description
  - [ ] Subtask with enough detail to act on
  - [ ] Another subtask
- [ ] **Next task**
  - [ ] ...

## Edge Cases & Decisions
- Decision or edge case and how it will be handled
- Another decision

## Test Strategy
- What to test and how (unit tests, integration tests, accessibility)
- Which components need new or updated tests

## Risks & Unknowns
- Anything that could block or complicate the work
```

### Task guidelines

- Order tasks by implementation sequence — what you'd build first to last
- Each top-level task should be roughly one commit's worth of work
- Subtasks should be concrete and actionable, not vague ("add responsive styles for mobile" not "make it responsive")
- Include tasks for test coverage, not just implementation
- Include a final task for definition of done checks

## Phase 5 — Review

After writing the plan, ask: "Does this match your understanding? Anything to add, remove, or reorder?"

Incorporate feedback, then confirm the plan is final.
