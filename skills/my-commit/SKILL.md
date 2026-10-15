---
name: my-commit
description: Commit the current work in any repo following Tommy's rules — named files only, comments removed, /verify passed, Conventional Commit subject with the reasoning in the body. Use when Tommy runs /my-commit or asks to commit.
disable-model-invocation: true
---

Commit the current work. Follow these steps in order and do not skip any. Do not stop to ask for approval once the gates pass: Tommy reviews diffs in the IDE.

## 1. See what is ours

Run `git status` (without `-uall`) and `git diff` (staged and unstaged) in parallel.

Other agents and Tommy may be working in the same checkout. Changes we did not make belong to someone else: never stage, revert or tidy them. List them in the final report and move on.

## 2. Remove working comments

Comments written while working come out now. Committed code targets zero comments, except in `website-front-end`, where a comment is allowed for something genuinely surprising or a magic number that isn't self-evident. Keep existing SCSS section banners (`// ===== Component Name =====`).

If a comment feels load-bearing, improve the code instead: a better name, a flatter branch or a small extracted function. Durable explanation goes in the project's docs (`docs/RUNBOOK.md` in `website-front-end`), and the reasoning goes in the commit body.

## 3. Verify

Run `/verify`. If any applicable gate fails, stop and report it. Do not commit.

## 4. Stage

Stage our files by name (`git add path/to/file`). Never `git add -A`, `git add .`, `git add -u` or `git commit -a`. Never stage `.env*` files, credentials or anything secret.

Then run:

```sh
git diff --cached | grep '^+' | grep -E '//|/\*|#'
```

Justify every line it prints, or remove it and restage.

## 5. Write the message

Run `git log --oneline -10` to match the repo's style.

Subject: Conventional Commits, `<type>: <short description>`, no scope, lowercase, imperative, no full stop, under 72 characters. Types: `feat`, `fix`, `style`, `refactor`, `test`, `docs`, `chore`, `perf`, `ci`.

Body: the reasoning — why this change, what it fixes, anything a reviewer would ask. Reference Monday tickets by title and full URL, never a bare ID. Skip the body only for a trivial change.

No `Co-Authored-By` lines and no mention of Claude or AI. Pass the message through a HEREDOC or a file in the scratchpad, never an inline quote-heavy string.

When the work covers several separate steps, make one commit per step.

## 6. Check the result

Run `git status` and `git show --stat HEAD`.

In `website-front-end`, the Husky GraphQL codegen hook can auto-stage `api/generated/`. If generated files were swept into the commit, `git reset --soft HEAD~1`, commit `api/generated/` alone as a `chore:`, then recommit our change.

Never push.

## 7. Report

List the commits (hash and subject), the gates that ran with their results, and any uncommitted changes that are not ours.
