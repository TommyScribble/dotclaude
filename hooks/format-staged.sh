#!/bin/bash

# Format only the files staged for the current commit, then re-stage them.
# Scoped alternative to running prettier/stylelint across the whole repo.
# No-ops outside git repos or projects without prettier/stylelint installed.

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

STAGED=$(git diff --cached --name-only --diff-filter=ACMR)
[ -z "$STAGED" ] && exit 0

PRETTIER_FILES=$(echo "$STAGED" | grep -E '\.(js|jsx|ts|tsx|json)$')
STYLE_FILES=$(echo "$STAGED" | grep -E '\.(css|scss)$')

if [ -n "$PRETTIER_FILES" ]; then
  echo "$PRETTIER_FILES" | tr '\n' '\0' | xargs -0 npx prettier --write --ignore-unknown 2>/dev/null
  echo "$PRETTIER_FILES" | tr '\n' '\0' | xargs -0 git add
fi

if [ -n "$STYLE_FILES" ]; then
  echo "$STYLE_FILES" | tr '\n' '\0' | xargs -0 npx stylelint --fix 2>/dev/null
  echo "$STYLE_FILES" | tr '\n' '\0' | xargs -0 git add
fi

exit 0
