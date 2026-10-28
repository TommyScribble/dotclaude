#!/bin/bash

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

[ -z "$COMMAND" ] && exit 0

block() {
  echo "BLOCKED: $1" >&2
  exit 2
}

SUBSTITUTED_KEYCHAIN_READ='\$\([[:space:]]*security[[:space:]]+find-(generic|internet)-password[^)]*\)'
COMMAND_WITHOUT_SUBSTITUTIONS=$(echo "$COMMAND" | sed -E "s/$SUBSTITUTED_KEYCHAIN_READ/KEYCHAIN_VALUE/g")

SAFE_ENV_TEMPLATE='\.env\.(example|sample|template|dist)([^a-zA-Z0-9_.-]|$)'
ENV_FILE='(^|[^a-zA-Z0-9_.-])\.env(\.[a-zA-Z0-9_.-]+)?([^a-zA-Z0-9_.-]|$)'
EXISTENCE_CHECK_ONLY='^[[:space:]]*(ls|test[[:space:]]+-[efs]|\[[[:space:]]+-[efs])[[:space:]]'

ENV_READER='^[[:space:](]*((sudo|command|exec|time|nice)[[:space:]]+)*(cat|bat|less|more|head|tail|nl|tac|grep|egrep|fgrep|rg|ag|ack|awk|gawk|sed|cut|sort|uniq|strings|xxd|od|hexdump|base64|openssl|cp|mv|scp|rsync|ln|tar|zip|source|\.|diff|cmp|vi|vim|nvim|nano|emacs|code|open|bash|sh|zsh|python|python3|node|ruby|perl|php|dotenv|env-cmd|tee|curl|git[[:space:]]+(add|show|cat-file|diff|stash))([[:space:]]|$)'
ENV_REDIRECT='<[[:space:]]*[^[:space:]<]*\.env'
RUNS_ON_FOUND_FILES='(^|[[:space:]])(xargs|-exec|-execdir|-ok)([[:space:]]|$)'

block_env_read() {
  block "this command reads a .env file, which holds secrets. Listing or checking it exists is fine. To know which keys it sets, ask Tommy, or read .env.example."
}

COMMAND_WITHOUT_MESSAGES=$(echo "$COMMAND" | sed -E "s/(-m|--message)[[:space:]=]*\"[^\"]*\"//g; s/(-m|--message)[[:space:]=]*'[^']*'//g")
COMMAND_FOR_ENV_CHECK=$(echo "$COMMAND_WITHOUT_MESSAGES" | sed -E "s/$SAFE_ENV_TEMPLATE//g")

if echo "$COMMAND_FOR_ENV_CHECK" | grep -qE "$ENV_FILE"; then
  echo "$COMMAND_FOR_ENV_CHECK" | grep -qE "$RUNS_ON_FOUND_FILES" && block_env_read

  while IFS= read -r SEGMENT; do
    echo "$SEGMENT" | grep -qE "$ENV_FILE" || continue
    if echo "$SEGMENT" | grep -qE "$ENV_READER" || echo "$SEGMENT" | grep -qE "$ENV_REDIRECT"; then
      block_env_read
    fi
  done <<< "$(echo "$COMMAND_FOR_ENV_CHECK" | awk '{ gsub(/&&|\|\||[;&|`]|\$\(/, "\n"); print }')"
fi

PRIVATE_KEY_OR_CREDENTIALS='(\.ssh/id_[a-z0-9_]+([^.a-z0-9_]|$)|\.ssh/[^[:space:]]*\.pem|\.pem([^a-zA-Z0-9]|$)|\.p12([^a-zA-Z0-9]|$)|\.key([^a-zA-Z0-9]|$)|\.aws/credentials|\.netrc|\.npmrc|\.config/gh/hosts\.yml|\.docker/config\.json|\.claude\.json)'

if echo "$COMMAND" | grep -qE "$PRIVATE_KEY_OR_CREDENTIALS"; then
  if ! echo "$COMMAND" | grep -qE "$EXISTENCE_CHECK_ONLY" || echo "$COMMAND" | grep -qE '[;&|]'; then
    block "this command touches a private key or credentials file. Checking it exists (ls, test -f) is fine; reading it is Tommy's call."
  fi
fi

if echo "$COMMAND_WITHOUT_SUBSTITUTIONS" | grep -qE 'security[[:space:]]+(find-(generic|internet)-password[^;&|]*[[:space:]]-[a-zA-Z]*[gw]|dump-keychain)'; then
  block "this prints a Keychain secret into the transcript. Use it inside a substitution so the value never reaches stdout, e.g. curl -H \"Authorization: Bearer \$(security find-generic-password -s <name> -w)\"."
fi

if echo "$COMMAND" | grep -qE '(^|[;&|(][[:space:]]*)(env|printenv|export[[:space:]]+-p|set)[[:space:]]*($|[;&|>)])'; then
  block "this dumps every environment variable, tokens included. Check one variable is set with: [ -n \"\$NAME\" ] && echo set."
fi

SECRET_VARIABLE='[A-Z0-9_]*(TOKEN|SECRET|PASSWORD|PASSWD|API_KEY|PRIVATE_KEY|ACCESS_KEY|CLIENT_SECRET|DSN)[A-Z0-9_]*'

if echo "$COMMAND" | grep -qE "(^|[;&|(][[:space:]]*)printenv[[:space:]]+$SECRET_VARIABLE"; then
  block "this prints a secret variable. Check it is set with: [ -n \"\$NAME\" ] && echo set."
fi

if echo "$COMMAND" | grep -qE "(^|[;&|(][[:space:]]*)(echo|printf|cat[[:space:]]+<<<)[^;&|]*\\\$\{?$SECRET_VARIABLE"; then
  block "this prints a secret variable. Check it is set with: [ -n \"\$NAME\" ] && echo set."
fi

if echo "$COMMAND" | grep -qE 'aws[[:space:]].*(secretsmanager[[:space:]]+get-secret-value|--with-decryption|configure[[:space:]]+(get|export-credentials)|sts[[:space:]]+get-session-token)'; then
  block "this prints decrypted AWS secrets or credentials. Listing parameter names (ssm describe-parameters, get-parameters-by-path without --with-decryption) is fine; reading values is Tommy's call."
fi

exit 0
