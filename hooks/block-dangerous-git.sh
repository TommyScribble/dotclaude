#!/bin/bash

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

DANGEROUS_PATTERNS=(
  "git push"
  "git reset --hard"
  "git clean -fd"
  "git clean -f"
  "git branch -D"
  "git checkout \."
  "git restore \."
  "push --force"
  "reset --hard"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: '$COMMAND' matches dangerous pattern '$pattern'. The user has prevented you from doing this." >&2
    exit 2
  fi
done

BLANKET_STAGING='git[[:space:]]+add[[:space:]]+(.*[[:space:]])?(-A|--all|-u|--update|\.)([[:space:];&|]|$)|git[[:space:]]+commit[[:space:]]+(.*[[:space:]])?(-[a-zA-Z]*a[a-zA-Z]*|--all)([[:space:]]|$)'

if echo "$COMMAND" | grep -qE "$BLANKET_STAGING"; then
  echo "BLOCKED: blanket staging can sweep in changes from another agent or the user. Stage the files you changed by name (git add path/to/file) and commit without -a." >&2
  exit 2
fi

exit 0