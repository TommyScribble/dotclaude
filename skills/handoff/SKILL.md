---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: What will the next session be used for?
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save to `/Users/tommy/Documents/Obsidian Vault/handoffs/` (create the directory if it doesn't exist; note the space in the path — quote it in shell commands) with a filename in the format `handoff-YYYY-MM-DD-<slug>.md` where the slug is a 2–3 word kebab-case summary of the session topic.

Include a "suggested skills" section in the document, which suggests skills that the agent should invoke.

Do not duplicate content already captured in other artifacts (PRDs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.