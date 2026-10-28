---
name: health-sweep
description: Audit the Claude Code dev environment for this project — list runaway/piled-up test & build processes and their parent hooks, measure the always-resent per-turn context footprint, audit every PreToolUse/PostToolUse hook (especially anything spawning Jest), and verify secret-access paths are guarded. Produces an evidence-based report saved to `~/Documents/Obsidian Vault/claude-docs/health-reports/` with measured numbers, then proposes scoped fixes ranked by impact. Use for "health sweep", "audit my environment", "why is Claude slow", "check my hooks", or when sessions feel sluggish or processes seem to be piling up.
disable-model-invocation: true
argument-hint: Optional — "report" to only diagnose and write the report (skip the fix proposal).
---

# Health Sweep

Audit the **Claude Code dev environment** for the current project: runaway processes, per-turn overhead, hook hygiene, and secret-access exposure. Every measurement is read-only. **Never kill a process, edit a hook, or change a config without first showing the user the exact command/diff and getting explicit approval.**

This is the environment-and-infra counterpart to `memory-audit` (which only touches the memory store). Use `memory-audit` for MEMORY.md consolidation; use this for processes, hooks, config footprint, and secrets.

Follow the steps in order.

## Step 1 — Run the read-only sweep

Run the bundled diagnostics from the project root:

```
bash ~/.claude/skills/health-sweep/sweep.sh
```

It never mutates anything and reports four sections with measured numbers:

1. **Test/build processes** — every jest/vitest/tsc/eslint/stylelint/`next build`/lint-staged process with PID, PPID, elapsed time, %CPU, %MEM, **and its parent command**. Flags any older than 600s as likely stale. IDE-owned helpers (WebStorm/JetBrains) are filtered out so genuine CLI runs and hook pile-ups stand out. The pile-up signature is a long-lived jest process whose parent is `lint-staged`, a hook `.sh`, or PID 1 (orphaned).
2. **Per-turn overhead** — word/byte counts of every file re-sent to the model each request (MEMORY.md index + all three CLAUDE.md layers) with a running total, plus each settings file's size and allow/deny rule counts.
3. **Hook audit** — every PreToolUse/PostToolUse/UserPromptSubmit/Stop hook across all four settings layers, each tagged with flags: `[SPAWNS-TEST/BUILD]`, `[POSTTOOLUSE-HEAVY: can pile up]`, `[MISSING-SCRIPT]`, `[NOT-EXECUTABLE]`.
4. **Secret-access exposure** — Read-tool deny coverage per settings file, whether `block-secret-access.sh` exists/is-executable/is-wired into a Bash PreToolUse matcher (the Read deny rules do **not** cover Bash — the hook is the real guard), and any broad file-reading Bash commands (`cat`, `less`, `env`…) in allow-lists that could bypass the Read deny.

Read the full output before continuing. Do not summarise from memory — the report must quote the actual numbers.

## Step 2 — Interpret against the baselines

- **Processes:** a single short-lived jest chain (elapsed seconds, descending PIDs from a zsh/pnpm parent) is a normal run in progress — not a leak. Flag only: (a) multiple stale jest processes, (b) any jest/test process parented by `lint-staged` or a hook script, or (c) orphans (PPID 1). A long-lived `next-server` is the dev server — note it, don't alarm.
- **Overhead:** total always-loaded context healthy under ~3000 words; MEMORY.md index alone under ~800 words. If MEMORY.md is over, recommend `memory-audit`. Flag any one CLAUDE.md that has ballooned.
- **Hooks:** a `[POSTTOOLUSE-HEAVY]` hook spawning Jest is the known pile-up cause — call it out as high priority. `[MISSING-SCRIPT]`/`[NOT-EXECUTABLE]` hooks silently no-op and must be flagged. A PreToolUse gate (lint-staged on commit, the guard scripts) is expected and fine.
- **Secrets:** the guard must be present, executable, **and** wired into a `Bash` matcher. Any broad file-reader in an allow-list is a real exposure. Note when a settings layer has no deny rules but is covered by a more-global layer (deny rules don't need to be repeated per layer).

## Step 3 — Write the evidence-based report

Save to `~/Documents/Obsidian Vault/claude-docs/health-reports/health-sweep-<YYYY-MM-DD>.md` (resolve the dir with `bash ~/.claude/skills/health-sweep/sweep.sh --reports-dir`, and create it if it doesn't exist). The report is the deliverable, not chat output — keep the chat response short and just give the path plus the top findings.

Structure:

```
# Health Sweep — <project> — <date>

## Summary
<2-3 lines: overall state, count of issues by severity>

## 1. Processes
<measured table; which are normal vs flagged, with PID + elapsed + parent>

## 2. Per-turn overhead
<measured word/byte totals; verdict vs the ~3000 / ~800 baselines>

## 3. Hooks
<each hook, its flags, and whether it's expected or a problem>

## 4. Secret-access
<deny coverage, guard status, any exposures>

## Proposed fixes (ranked by impact)
<see Step 4 — leave this as proposals only>
```

Every claim must cite a measured number from the sweep. No guesses — if something wasn't measured, say so.

## Step 4 — Propose scoped fixes, ranked — but change nothing yet

In the report's final section and in the chat, list fixes **ranked by impact** (highest first). For each: the problem, the precise fix, and its blast radius. If the user invoked with `report`, stop after writing the report — proposals only, no offer to apply.

**Hard rule — nothing destructive without a shown diff and explicit approval:**

- **Killing a process:** show the exact `kill <PID>` command and the full `ps` line it targets. Get a yes before running it. Never `kill -9` or `pkill` by name (could hit the IDE or an unrelated run).
- **Removing/editing a hook or settings rule:** show the exact before/after of the JSON or script as a diff. Get a yes before editing. Edit the narrowest layer that fixes it.
- **Deleting/trimming a config or memory file:** look at the file first; if its content contradicts how it was described, surface that instead of trimming. Get a yes.

Apply approved fixes one at a time, smallest blast radius first, and re-run `sweep.sh` afterward to confirm the issue is gone. Report the before/after numbers.

## Notes

- IDE-owned node helpers (WebStorm/JetBrains) are filtered from the process list on purpose; never propose killing an IDE process. If you use a different IDE (e.g. VS Code), add its process name to the filter in `sweep.sh`.
- The report lands in the Obsidian vault (`claude-docs/health-reports/`), outside any repo. No commit needed.
- This skill never touches application code. It only inspects processes and Claude Code config, and only mutates them on explicit approval.
- If the reports dir can't be created, tell the user and offer to print the report inline instead.