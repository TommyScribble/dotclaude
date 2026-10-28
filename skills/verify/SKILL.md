---
name: verify
description: Run the repo's verification gates against the current change before calling it done. Use before saying a change works, before committing, before writing a handoff that claims verified state, or when the user runs /verify.
argument-hint: Optional — "full" to run every gate including the slow ones, or a gate name to run just that one.
---

Prove the current change works before saying it does. A gate only counts if you ran it in this session against the current code.

## 1. Work out what changed

Run `git status` and `git diff --stat` (plus `git diff --cached --stat`). Decide which gates the change touches using the tables below. Docs-only changes need no gates — say so and stop.

## 2. Pick the gates for this repo

Use the repo's own package manager: **pnpm** in `afs-turborepo-poc` and `website-front-end` (since 2026-10-16), **npm** everywhere else. Never mix them.

### website-front-end

| Gate | Command | When |
|---|---|---|
| Types | `pnpm run check-types` | Always for code changes |
| Unit tests | `pnpm --filter website exec jest <changed area>` first, then `pnpm test` before committing | Always for code changes |
| Build | `pnpm run build` | Config, dependency, `next.config`, routing or SSR changes |
| CSS fingerprint | `pnpm run css:fingerprint:diff` | SCSS, styling dependencies, build tooling |
| Local VRT | `pnpm --filter website run vrt:local:compare` (expect all identical) | Visual components, styles, dependency upgrades |

### afs-turborepo-poc

| Gate | Command | When |
|---|---|---|
| Types | `pnpm check-types` | Always for code changes |
| Lint | `pnpm lint` | Always for code changes |
| Tests | `pnpm turbo run test --filter=<affected>...` then `pnpm test` before committing | Always for code changes |
| Build | `pnpm build` | Config, packages, `next.config`, routing |
| Pruned Docker build | `docker build -f apps/<app>/Dockerfile -t afs-poc/<app> .` for each affected app | `turbo.json`, `microfrontends.json`, shared packages, Dockerfiles, anything read at build time |

### component-library

| Gate | Command | When |
|---|---|---|
| Types | `npm run types:check` | Always for code changes |
| Tests | `npm test` | Always for code changes |
| Build | `npm run build` | Exports, types, build config |

### Any other repo

Read `package.json` scripts and use the type-check, lint, test and build equivalents.

With the `full` argument, run every gate for the repo. With a gate name, run only that gate.

## 3. Run them

- Run cheap gates first (types, targeted tests) and stop at the first failure to fix it before moving on.
- VRT and Docker builds are slow. Run them when the table says they apply; otherwise list them as skipped with the reason.
- When a gate fails, read the actual output and find the cause. Do not retry hoping it passes.
- Never call a failure "baseline" or "pre-existing" without evidence: run the same gate on the base commit (a temporary `git worktree` is fine, remove it afterwards) and show it failing there too.

## 4. Report

End with a short table — gate, command, result (pass / fail / skipped + reason). Only say the change is done or verified if every applicable gate passed. If something was skipped, say so plainly.
