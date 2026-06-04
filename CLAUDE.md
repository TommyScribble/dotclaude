# Global Instructions

## General Rules

- Keep changes minimal and scoped to what was requested. Do not refactor, restyle, or modify files beyond the specific ask. If a file wasn't mentioned, don't touch it.

## Scope Discipline

- When asked to fix or modify a specific page/file, do NOT explore all usages of shared components unless explicitly requested.
- Confirm the target file/scope before making changes to shared components.
- If a change could affect multiple consumers, ask first.

## Investigation Before Action

- For bug reports, investigate the actual root cause before proposing fixes. Avoid speculative guesses (cache clearing, file recreation, invalid characters).
- If unsure, run diagnostic commands (npm install status, file existence checks, URL inspection) before edits.
- Don't read 5+ files exploring when the user has given a concrete bug report — form a hypothesis quickly and verify it.

## CSS Fixes

- When fixing CSS issues, investigate the actual cause before applying fixes. Do not assume margin/padding is the problem — check alignment, parent containers, and layout context first.
- Do not change parent component styles unless explicitly asked — a fix in a shared parent can break every other consumer.

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
