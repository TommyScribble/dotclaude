# Global Instructions

## General Rules

- Keep changes minimal and scoped to what was requested. Do not refactor, restyle, or modify files beyond the specific ask. If a file wasn't mentioned, don't touch it.

## Scope Discipline

- When asked to fix or modify a specific page/file, do NOT explore all usages of shared components unless explicitly requested.
- Confirm the target file/scope before making changes to shared components.
- If a change could affect multiple consumers, ask first.
- Before structural changes (moving code into packages, refactors, new abstractions), give me the minimal option and the systemic option with files touched, then wait for me to pick.
- When I make a short reference ("step 4", "the run", "that ticket") and more than one thing in context matches, restate which one you mean in one line before acting.

## Investigations

- For investigations with several independent threads, fan out to subagents and bring back findings with file references, so the main context stays free for implementation.

## Handoffs

- When a chunk of work is committed and the next step starts a new phase, or the context is getting long, end the reply with a one-line offer to `/handoff` and `/clear`. Don't write the handoff until I say so.

## Shared Working Trees

- Other agents and I may be working in the same checkout. Before staging or committing, run `git status`. Changes you didn't make belong to someone else: never stage, revert or tidy them. Mention them and move on.

## Commits

- When the work includes committing, commit once `/verify` passes without stopping to ask for approval. I review diffs in the IDE. Stage named files only.

## Monday Tickets

- Refer to a ticket by its title and full URL (`https://accommodation-for-students-team.monday.com/boards/<boardId>/pulses/<itemId>`), never a bare ID. This applies in chat, docs and handoffs, not just on the board.

## Shell

- My shell is zsh. Quote globs, and paths with spaces or brackets. Write anything multi-line or quote-heavy to a script in the scratchpad and run that, instead of inlining it.

## Investigation Before Action

- For bug reports, investigate the actual root cause before proposing fixes. Avoid speculative guesses (cache clearing, file recreation, invalid characters).
- If unsure, run diagnostic commands (npm install status, file existence checks, URL inspection) before edits.
- Don't read 5+ files exploring when the user has given a concrete bug report — form a hypothesis quickly and verify it.

## CSS Fixes

- When fixing CSS issues, investigate the actual cause before applying fixes. Do not assume margin/padding is the problem — check alignment, parent containers, and layout context first.
- Do not change parent component styles unless explicitly asked — a fix in a shared parent can break every other consumer.

## Comments

- Comments are welcome **while we are working** — they show me why you made a change and I read them when reviewing.
- They must not reach the remote. Deleting them is the last step of every change, before committing, without me asking.
- Committed code targets **zero comments**, except in `website-front-end`, where a comment is allowed for something genuinely surprising or a magic number that isn't self-evident (per that repo's CLAUDE.md). Everything else still goes, including "why this and not that" explanations.
- Outside that carve-out, do not argue an exception applies. If a comment feels load-bearing, the code is not simple enough: use a better name, a flatter branch, or a small extracted function.
- The reasoning belongs in the commit message, not the source. Durable "how this works and why" explanation belongs in the project's docs (in `website-front-end`, `docs/RUNBOOK.md`) — prose there is welcome and is what it is for.
- Exception: keep existing structural section banners in SCSS (`// ===== Component Name =====`) — those are an established file convention, not commentary.
- Before committing, run `git diff --cached | grep '^+' | grep -E '//|/\*|#'` and justify every line it prints.

## Code Style

- No semicolons
- No trailing commas
- No abbreviations in variable names, parameters, or callbacks. Use short descriptive words: `(number)` not `(n)`, `(item)` not `(i)`, `(event)` not `(e)`
- Import ordering (each group separated by a blank line):
  1. Third-party packages (`react`, `next/*`, `classnames`, `@afs/components/*`)
  2. Project-level non-component imports (config, local data, contexts)
  3. Components — ordered by atomic level (atoms → molecules → organisms → templates)
  4. Constants
  5. Sibling/local imports (same directory)
  6. Types
  7. Assets (SVGs, images)
  8. Styles (`styles.module.scss` always last)
- Groups 2–5 form one contiguous block with no blank lines between them
- Blank line after the last import
- Blank line between interface/type definitions and code
- Blank line between groups of related state declarations
- Blank line between each function/handler definition
- Blank line between logical sections within JSX
- No multiple consecutive blank lines
