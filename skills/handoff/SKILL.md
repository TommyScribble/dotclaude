---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: What will the next session be used for?
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save to `/Users/tommy/Documents/Obsidian Vault/handoffs/` (create the directory if it doesn't exist; note the space in the path — quote it in shell commands) with a filename in the format `handoff-YYYY-MM-DD-<slug>.md` where the slug is a 2–3 word kebab-case summary of the session topic.

## Before writing

Gather the facts from the repo, not from memory:

- `git log --oneline` for the commits made this session
- `git status` for uncommitted changes — work out which are ours and which came from another agent or the user
- Which gates actually ran this session and their results (from `/verify` output). Do not run new gates just to fill the section.

## Sections

1. **Goal and status** — what the work is for and where it stands, in a few lines.
2. **Commits this session** — hash and subject for each.
3. **Verified state** — only gates that ran this session against the current code, with results. Anything not run goes under "not verified", stated plainly.
4. **Known failures** — each marked **BASELINE** (with the evidence: the same gate failing on the base commit) or **INTRODUCED / UNVERIFIED**. Never mark something baseline without that evidence.
5. **Uncommitted changes** — split into "ours" (with what's left to do) and "not ours" (leave alone).
6. **Deferred items and open decisions** — with full Monday URLs or ticket titles, never bare IDs.
7. **Next step** — the exact first action for the next session.
8. **Suggested skills** — skills the next agent should invoke.

Leave out any section with nothing to say rather than writing "none".

## Rules

Do not duplicate content already captured in other artifacts (PRDs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.