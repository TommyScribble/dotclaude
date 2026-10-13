#!/bin/bash

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
WORKING_DIRECTORY=$(echo "$INPUT" | jq -r '.cwd // empty')

[ -z "$COMMAND" ] && exit 0

block() {
  echo "BLOCKED: $1" >&2
  exit 2
}

if echo "$COMMAND" | grep -qE '(^|[;&|[:space:]])p?npm[[:space:]]+(i|install|ci|add|uninstall|un|rm|remove|update|up|upgrade)([[:space:]]|$)'; then
  RUNNING=$(pgrep -fl 'next dev|next-server|turbo dev|turbo run dev|storybook dev|start-storybook|http-server' 2>/dev/null)
  if [ -n "$RUNNING" ]; then
    block "a dev server or Storybook is running, and installing under it breaks it. Ask Tommy to stop it first, then retry. Running: $(echo "$RUNNING" | head -3 | tr '\n' ' ')"
  fi
fi

if echo "$COMMAND" | grep -qE 'git[[:space:]]+stash[[:space:]]+(drop|clear|pop)([[:space:]]|$)'; then
  block "git stash drop, clear and pop can lose Tommy's kept stash, so only Tommy runs them. Use 'git stash apply' and leave the dropping to him."
fi

STASH_COUNT=$(echo "$COMMAND" | grep -oE 'git[[:space:]]+stash' | wc -l | tr -d ' ')
if [ "$STASH_COUNT" -ge 2 ] && echo "$COMMAND" | grep -qE 'git[[:space:]]+stash[[:space:]]+(pop|apply)'; then
  block "never chain git stash with pop/apply in one command: on a clean tree the stash is a no-op and the pop applies and drops Tommy's kept stash. Run them as separate steps and check 'git stash list' in between."
fi

if echo "$COMMAND" | grep -qE '(^|[;&|[:space:]])npx[[:space:]]+cypress'; then
  case "$WORKING_DIRECTORY" in
    */acceptance-tests-cypress*) ;;
    *)
      if ! echo "$COMMAND" | grep -qE 'cd[[:space:]]+[^;&|]*acceptance-tests-cypress'; then
        block "npx cypress outside acceptance-tests-cypress downloads the latest Cypress instead of the suite's pinned version. cd acceptance-tests-cypress first and use its npm scripts."
      fi
      ;;
  esac
fi

if echo "$COMMAND" | grep -qE '(^|[;&|[:space:]])git[[:space:]]+commit'; then
  COMMENT_LINES=$(git -C "${WORKING_DIRECTORY:-.}" diff --cached -U0 -- '*.js' '*.jsx' '*.ts' '*.tsx' '*.scss' '*.css' 2>/dev/null \
    | grep -E '^\+[^+]' \
    | grep -E '^\+[[:space:]]*(//|/\*|\*[[:space:]/]|\{/\*)|[[:space:]]//[[:space:]]' \
    | grep -vE '^\+[[:space:]]*// =+')
  if [ -n "$COMMENT_LINES" ]; then
    MESSAGE="Staged lines contain comments. Justify each one or remove it before committing:
$COMMENT_LINES"
    jq -n --arg message "$MESSAGE" '{
      systemMessage: $message,
      hookSpecificOutput: { hookEventName: "PreToolUse", additionalContext: $message }
    }'
  fi
fi

exit 0
