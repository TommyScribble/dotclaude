---
name: pickup
description: Pick up from the most recent /handoff document. Use after /clear, or any time the user wants to resume work captured in a handoff.
argument-hint: Optional — slug or date of a specific handoff to load instead of the latest.
---

Locate the most recent handoff document and continue from it.

1. List `/Users/tommy/Documents/Obsidian Vault/handoffs/handoff-*.md` (note the space in the path — quote it in shell commands). Pick the latest by filename date (format: `handoff-YYYY-MM-DD-<slug>.md`); break ties by mtime.
2. If the user passed an argument, filter to handoffs whose filename contains that string (date or slug) and pick the latest match. If nothing matches, tell the user and stop.
3. Read the chosen handoff in full.
4. Briefly tell the user which handoff you loaded (filename + one-line topic) so they can confirm it's the right one.
5. Follow the handoff's instructions. If it has a "suggested skills" section, invoke those skills via the Skill tool. If it references PRDs, plans, issues, or commits by path/URL, read them as needed before acting.
6. Do not re-summarise the entire handoff back to the user — they wrote (or asked for) it. Just confirm the pickup and start working.