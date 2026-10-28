---
name: memory-audit
description: Audit and consolidate the agent memory store for the current project — measure the MEMORY.md index, find orphans and dangling [[links]], detect duplicate/same-theme files, and (on approval) merge them, rewrite the index, and fix cross-links. Use for "audit memory", "consolidate memory", "memory housekeeping", or when sessions feel slow from a bloated memory index.
disable-model-invocation: true
argument-hint: Optional — "report" to only diagnose (skip the consolidation proposal).
---

# Memory Audit

Audit the **agent memory store** (`~/.claude/projects/<encoded-cwd>/memory/` — the `MEMORY.md` index plus the individual memory files). This is the file-based memory loaded every session, **not** `CLAUDE.md` (use `claude-md-management` for that).

The `MEMORY.md` index is re-sent on every request in every session, so a bloated index slows responses independent of context clearing. The goal of this skill is to keep it lean and internally consistent.

Follow the steps in order. **The diagnostics are read-only; never delete, merge, or rewrite anything before showing the full report and getting explicit approval.**

## Step 1 — Run the read-only audit

Run the bundled diagnostics script from the project root:

```
bash ~/.claude/skills/memory-audit/audit.sh
```

It locates the memory dir for the current project and reports:
- **Index size** — `MEMORY.md` word/byte count (the per-session cost).
- **File counts** — total, broken down by prefix (`feedback`, `project`, `reference`).
- **Orphans** — memory files not linked from `MEMORY.md` (never surfaced).
- **Dangling `[[links]]`** — `[[...]]` links whose target slug matches no file's name/frontmatter.
- **Broken index entries** — `MEMORY.md` markdown links pointing at missing files.
- **Largest files** — potential bloat / merge targets.

If the script reports no memory dir, stop and tell the user (this project may have no memory yet).

## Step 2 — Identify consolidation candidates

Read `MEMORY.md` and skim the file list. Look for clusters of files covering the **same theme** that could merge into one (each merged file = one fewer index line, which is the win). Typical clusters:

- Several `feedback_*` files on one topic (commits, testing, storybook, code style, SCSS, workflow/checks).
- Near-duplicate rules split across files.
- Stale `project_*` notes describing work that's since shipped (candidates to archive, not merge — confirm first).

Be conservative with `project_*` and `reference_*` files: they often hold active, unresolved state where nuance matters. Default to consolidating `feedback_*` (stable preferences) and leaving active project memory alone unless the user asks.

To merge accurately you must read the **full body** of every file in a proposed group — dump them in one go rather than many reads:

```
cd "$(bash ~/.claude/skills/memory-audit/audit.sh --dir)" && for f in feedback_*.md; do echo "=== $f ==="; cat "$f"; done
```

## Step 3 — Show the report and propose a plan

Present the full audit findings to the user, then propose a merge plan as a table (`new file` ← `files it merges`). State the projected before/after index size. **Stop and get explicit approval before any destructive action.** If the user invoked with `report`, stop here — diagnostics only.

## Step 4 — Consolidate (only after approval)

For each approved group:

1. **Write the merged file first.** Preserve every distinct rule plus its **Why** and **How to apply**, and keep the concrete corrective quotes/dates that explain why a rule exists — consolidation removes duplication, not information. Set `name:` in the frontmatter equal to the filename slug, with `metadata:\n  type: feedback` (or the appropriate type).
2. **Then archive the merged originals and any retired notes.** Append each file's full body under a dated heading to `~/Documents/Obsidian Vault/claude-docs/Memory archive.md`, then remove it from the memory dir. Never delete a memory without archiving it first. Look at each file before archiving it — if its content contradicts how it was described, surface that instead.
3. **Update `MEMORY.md` in place** so each merged file is a single index line: `- [Title](file.md) — one-line hook`. Keep the existing section headings and their order, put each merged line in the section its originals came from, and leave other sections untouched unless they were in scope.

## Step 5 — Fix cross-links

Merging changes slugs, so old `[[links]]` in surviving files (often `project_*`/`reference_*`) go dangling. Find them and repoint each to the consolidated file:

```
cd "$(bash ~/.claude/skills/memory-audit/audit.sh --dir)" && grep -rln '\[\[old_slug\]\]' *.md
```

Read each file before editing it, then update the `[[old_slug]]` → `[[new_slug]]`.

## Step 6 — Verify

Re-run `bash ~/.claude/skills/memory-audit/audit.sh`. Confirm: **zero dangling links, zero orphans, zero broken index entries**, and report the before/after index size and file count. Do not claim success without re-running the audit.

## Notes

- This skill only touches the memory store. It never modifies `CLAUDE.md` or project code.
- A healthy index is roughly under ~800 words; flag consolidation when it grows well past that or when one prefix exceeds ~15 files.
- Memory edits are local files — no commit/push needed unless the user keeps `~/.claude` under version control (see their config repo memory if present).