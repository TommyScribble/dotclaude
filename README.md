# dotclaude

My personal [Claude Code](https://claude.com/claude-code) configuration — global instructions, settings, hooks, skills, and agents, version-controlled so it has history and survives machine changes.

This is the live contents of `~/.claude/`. Machine-local state (sessions, caches, auth, plugins) is excluded via `.gitignore`; only real config is tracked.

Built from the excellent config shared by my great teammate **Vee** 🙌 — trimmed and adapted to my setup, but the best ideas in here (the git safety hook, the statusline, most of the skills) are hers.

## What's inside

| Path | What it is |
|---|---|
| `CLAUDE.md` | Global instructions loaded into every session — behaviour guardrails (minimal scoped changes, root-cause-first debugging) and code style (no semicolons, import ordering) |
| `settings.json` | Permissions allowlist, `.env`/secrets read deny-list, hooks wiring, statusline, commit attribution off, `claude-md-management` plugin |
| `hooks/block-dangerous-git.sh` | PreToolUse hook that blocks destructive git commands before they run: **all** `git push` (I push manually, by choice), `reset --hard`, `clean -f`, `restore .`, `checkout .`, `branch -D` |
| `hooks/format-staged.sh` | PreToolUse hook on `git commit` — runs prettier + stylelint on **staged files only**, then re-stages them |
| `skills/` | Custom slash-command skills (see below) |
| `agents/write-test.md` | Subagent that generates tests following our `setup()` + test-data conventions |
| `statusline-command.sh` | Statusline showing directory, git branch, model, 5h/7d rate-limit usage, and context usage — colour-coded |

## Skills

| Skill | Purpose |
|---|---|
| `/tdd` | Red-green-refactor cycle (opt-in only — won't auto-trigger) |
| `/handoff` / `/pickup` | Save a session as a handoff doc in `~/claude-handoffs/`; resume it later |
| `/scope-ticket` | Turn a vague ticket into a phased, checkboxed implementation plan |
| `/triage-bugs` | Paste multiple bugs → parallel subagents repro, root-cause, and fix each |
| `/explain` | Explain what was just written, why, and what alternatives existed |
| `/teach` | Mid-task concept teaching aimed at durable understanding |
| `/grill-me` | Relentless interview to stress-test a plan or design |
| `/ubiquitous-language` | Extract a DDD-style domain glossary from the conversation |
| `/request-refactor-plan` | Plan a refactor in tiny commits, file it as a GitHub issue |
| `/screenshots` | Pull the latest N screenshots from `~/Desktop` into context |

## Setup on a new machine

Requires `jq` (pre-installed on recent macOS) for the hooks.

```sh
# Fresh machine (no ~/.claude yet)
git clone <repo-url> ~/.claude

# Machine where Claude Code has already run (~/.claude exists)
cd ~/.claude
git init
git remote add origin <repo-url>
git fetch origin
git reset origin/main          # adopt repo state without touching local files
git checkout -- .              # then materialise tracked files
```

Then restart Claude Code to load everything.

## Notes

- The `git push` block in `block-dangerous-git.sh` is deliberate: Claude prepares commits, I push.
- `format-staged.sh` no-ops outside git repos and in projects without prettier/stylelint, so it's safe globally.
- Duplicates of Claude Code built-ins (`/commit`, `/verify`, `/code-review`, `/simplify`) from the original share were dropped rather than installed.
