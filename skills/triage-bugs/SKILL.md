---
name: triage-bugs
description: >
  Fan out multiple bugs to parallel subagents — one per bug — each of which reproduces the bug
  with a failing test, identifies the root cause, implements a minimal fix, verifies the test
  passes, and reports back with a summary diff. All agents run concurrently; results are
  consolidated for side-by-side review before any commits. Use when the user pastes two or more
  bug descriptions and wants them investigated in parallel.
---

# Parallel Bug Triage

## Goal

Fix N bugs concurrently by spawning one isolated subagent per bug. Each agent works independently;
you review all results together before committing anything.

## Workflow

### 1. Parse bugs from `$ARGUMENTS`

Split the input into individual bug descriptions. Number them. If only one bug is provided, warn
the user that this skill is designed for multiple bugs and proceed anyway with a single agent.

### 2. Spawn one agent per bug — all in a single message

Call the Agent tool N times in a single response so all agents run concurrently. For each agent:

**Agent prompt template:**

```
Bug #N: <description>

You are investigating a single specific bug. Do NOT read the entire codebase.

Steps:
1. Read only the files most likely involved (start from the component/module named in the bug).
2. Write a failing test that reproduces the bug. Place it in the correct *.test.tsx alongside the
   component. The test must fail before your fix.
3. Identify the root cause — one sentence.
4. Implement the minimal fix. Do not refactor, restyle, or touch unrelated code.
5. Verify the failing test now passes: run `npx jest --findRelatedTests <file> --forceExit`.
6. Report back with:
   - Root cause (one sentence)
   - Fix summary (one sentence)
   - Files changed (list)
   - Test name that was added
   - Whether tests pass (yes/no + output snippet if no)

Do NOT commit. Do NOT run /check or /commit. Just report.
```

Use `isolation: "worktree"` on each agent so they work on independent copies of the repo and
cannot collide on the same files.

### 3. Wait for all agents to return

Do not present partial results. Wait until every agent has reported back.

### 4. Present a consolidated side-by-side review

For each bug, show a section:

```
## Bug #N — <one-line description>

**Root cause:** ...
**Fix:** ...
**Test added:** `<test name>`
**Files changed:** <list>
**Tests pass:** yes / no
```

Then ask: "Which fixes should I commit? (all / list numbers / none)"

### 5. Commit approved fixes

For each approved fix, run `/commit` on that worktree branch. Use a single-line Conventional
Commits message: `fix: <what changed>`.

## Rules

- Agents must not read files unrelated to their bug.
- Agents must not commit.
- Agents must not run `/check`, `/commit`, or any formatting commands.
- Never present partial results — wait for all agents before the consolidated review.
- If an agent fails or times out, report it as "inconclusive" and continue with the others.
- Do not collapse or abbreviate agent output in the consolidated review — show the full report for
  each bug so the user can make an informed commit decision.