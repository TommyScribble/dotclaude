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

LIVE_DOMAIN='accommodationforstudents\.com'

if echo "$COMMAND" | grep -qiE "$LIVE_DOMAIN"; then
  if echo "$COMMAND" | grep -qE '(^|[;&|[:space:]])(curl|wget|http|https|xh)[[:space:]]' \
    && echo "$COMMAND" | grep -qE '(-X|--request|--method)[[:space:]=]*["'\'']?(POST|PUT|PATCH|DELETE)|[[:space:]](-d|--data[a-z-]*|-F|--form[a-z-]*|--json|-T|--upload-file|--post-data|--post-file)([[:space:]=]|$)'; then
    block "this sends data to the live site. Reading it (GET) is fine, but writes to accommodationforstudents.com need Tommy to run them himself."
  fi

  if echo "$COMMAND" | grep -qE '(^|[;&|[:space:]/])(cypress|playwright|k6|autocannon|artillery|siege|wrk|hey|ab)[[:space:]]' \
    || echo "$COMMAND" | grep -qiE "(base_?url|base-url)[\"']?[[:space:]=:]+[\"']?https?://[^[:space:]]*$LIVE_DOMAIN"; then
    block "test runners and load tools must never point at the live site: they create accounts, bookings and enquiries, or add load. Point them at localhost or a test environment."
  fi
fi

PROD_WORD='(^|[^a-z0-9])(prod|production)([^a-z0-9]|$)'
AWS_READ_ONLY='^aws[[:space:]]+(--[a-z-]+[[:space:]]+[^[:space:]]+[[:space:]]+)*[a-z0-9-]+[[:space:]]+(describe-|list-|get-|head-|ls([[:space:]]|$)|tail([[:space:]]|$)|wait[[:space:]])'
SENTRY_READ_ONLY='^sentry-cli[[:space:]]+(info|--help|--version|(releases|deploys|issues|projects|repos|organizations)[[:space:]]+(list|info))([[:space:]]|$)'

while IFS= read -r INVOCATION; do
  [ -z "$INVOCATION" ] && continue
  echo "$INVOCATION" | grep -qiE "$PROD_WORD" || continue
  echo "$INVOCATION" | grep -qE "$AWS_READ_ONLY|$SENTRY_READ_ONLY" && continue
  block "'$INVOCATION' changes something named prod/production. Read-only calls (describe, list, get, ls, tail, info) are fine; anything that writes to production is Tommy's to run."
done < <(echo "$COMMAND" | grep -oE '(^|[;&|[:space:]])(aws|sentry-cli)[[:space:]][^;&|]*' | sed -E 's/^[;&|[:space:]]+//')

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
