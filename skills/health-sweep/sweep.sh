#!/usr/bin/env bash
#
# Read-only health sweep of the Claude Code dev environment.
# Usage:
#   bash sweep.sh                 # full diagnostics report (text, for transcription into the health-reports file)
#   bash sweep.sh --reports-dir   # print the health-reports dir path only
#
# Never mutates anything. Never kills a process or edits a config. Safe to run any time.

# --- locations -------------------------------------------------------------

PROJECT_ROOT="$(pwd)"
REPORTS_DIR="$HOME/Documents/Obsidian Vault/claude-docs/health-reports"

if [ "${1:-}" = "--reports-dir" ]; then
  echo "$REPORTS_DIR"
  exit 0
fi

# Settings files that are merged into the effective config (most-specific last).
SETTINGS_FILES=(
  "$HOME/.claude/settings.json"
  "$HOME/.claude/settings.local.json"
  "$PROJECT_ROOT/.claude/settings.json"
  "$PROJECT_ROOT/.claude/settings.local.json"
)

# Files that are re-sent to the model on every request (the per-turn footprint).
MEM_DIR="$HOME/.claude/projects/$(echo "$PROJECT_ROOT" | sed 's#/#-#g')/memory"
CONTEXT_FILES=(
  "$MEM_DIR/MEMORY.md"
  "$HOME/.claude/CLAUDE.md"
  "$PROJECT_ROOT/CLAUDE.md"
  "$PROJECT_ROOT/.claude/CLAUDE.md"
)

etime_to_secs() {
  # converts [[dd-]hh:]mm:ss -> seconds
  awk -F'[:-]' '{
    if (NF==4)      print ($1*86400)+($2*3600)+($3*60)+$4
    else if (NF==3) print ($1*3600)+($2*60)+$3
    else if (NF==2) print ($1*60)+$2
    else            print $1
  }'
}

echo "######################################################################"
echo "# Claude Code health sweep"
echo "# project: $PROJECT_ROOT"
echo "# host:    $(hostname -s)   date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "######################################################################"
echo ""

# --- 1. runaway / piled-up test & build processes --------------------------

echo "=== 1. Test/build processes (runaway / piled-up detection) ==="
echo "    threshold for 'likely stale': elapsed > 600s (10 min)"
echo ""
# match the runners that pile up; exclude this sweep and editors/IDE servers
RUNNER_RE='jest|vitest|next build|next-server|tsc|stylelint|eslint|lint-staged|turbo run|p?npm (run )?test|p?npm run build'
MATCHES="$(ps -Ao pid,ppid,etime,pcpu,pmem,command \
  | grep -iE "$RUNNER_RE" \
  | grep -viE 'grep -|sweep.sh|sonarlint|acp-agents|wallaby/mcp|JetBrains|WebStorm|Library/Caches' )"

if [ -z "$MATCHES" ]; then
  echo "  (no test/build runner processes found — clean)"
else
  count=$(echo "$MATCHES" | wc -l | tr -d ' ')
  jestcount=$(echo "$MATCHES" | grep -ic 'jest' || true)
  echo "  found $count runner process(es); $jestcount mention jest"
  echo ""
  printf "  %-7s %-7s %-10s %-5s %-5s %s\n" PID PPID ELAPSED %CPU %MEM COMMAND
  echo "$MATCHES" | while read -r pid ppid etime pcpu pmem command; do
    secs=$(echo "$etime" | etime_to_secs)
    flag=""
    [ "${secs:-0}" -gt 600 ] && flag="  <-- STALE (${secs}s)"
    # parent command — reveals whether a Claude hook (lint-staged / hook script) spawned it
    pcmd="$(ps -o command= -p "$ppid" 2>/dev/null | cut -c1-60)"
    printf "  %-7s %-7s %-10s %-5s %-5s %.70s%s\n" "$pid" "$ppid" "$etime" "$pcpu" "$pmem" "$command" "$flag"
    printf "          parent[%s]: %s\n" "$ppid" "${pcmd:-<gone>}"
  done
  echo ""
  echo "  NOTE: a parent of 'lint-staged', a hook .sh, or PID 1 (re-parented/orphaned)"
  echo "        on a long-running jest process is the signature of a hook pile-up."
fi
echo ""

# --- 2. per-turn overhead: always-resent context footprint -----------------

echo "=== 2. Per-turn overhead (footprint re-sent to the model every request) ==="
echo "    proxy for overhead = bytes/words of always-loaded context + config."
echo ""
total_words=0
printf "  %-9s %-9s %s\n" WORDS BYTES FILE
for f in "${CONTEXT_FILES[@]}"; do
  if [ -f "$f" ]; then
    w=$(wc -w < "$f" | tr -d ' '); b=$(wc -c < "$f" | tr -d ' ')
    total_words=$((total_words + w))
    printf "  %-9s %-9s %s\n" "$w" "$b" "$f"
  else
    printf "  %-9s %-9s %s\n" "-" "-" "$f (absent)"
  fi
done
echo "  ---"
echo "  total always-loaded context: ~$total_words words"
echo "  (rough guide: healthy < ~3000 words; MEMORY.md index alone < ~800 words)"
echo ""
echo "  Settings file sizes + permission-rule counts:"
for f in "${SETTINGS_FILES[@]}"; do
  if [ -f "$f" ]; then
    b=$(wc -c < "$f" | tr -d ' ')
    allow=$(jq '(.permissions.allow // []) | length' "$f" 2>/dev/null || echo "?")
    deny=$(jq '(.permissions.deny // []) | length' "$f" 2>/dev/null || echo "?")
    printf "    %-9s bytes  allow:%-3s deny:%-3s  %s\n" "$b" "$allow" "$deny" "$f"
  else
    printf "    %-9s         %s\n" "absent" "$f"
  fi
done
echo ""

# --- 3. hook audit (PreToolUse / PostToolUse) ------------------------------

echo "=== 3. Hook audit (PreToolUse / PostToolUse) ==="
echo "    flags: Jest/test/build-spawning commands, PostToolUse long-runners, missing scripts."
echo ""
for f in "${SETTINGS_FILES[@]}"; do
  [ -f "$f" ] || continue
  has=$(jq 'has("hooks")' "$f" 2>/dev/null)
  [ "$has" != "true" ] && continue
  echo "  --- $f ---"
  for event in PreToolUse PostToolUse UserPromptSubmit Stop SubagentStop; do
    n=$(jq "(.hooks.$event // []) | length" "$f" 2>/dev/null)
    [ "${n:-0}" -eq 0 ] && continue
    jq -r ".hooks.$event[] | \"\(.matcher // \"*\")\t\(.hooks[].command)\"" "$f" 2>/dev/null \
    | while IFS=$'\t' read -r matcher command; do
        flags=""
        # spawns jest/test/build?
        echo "$command" | grep -qiE 'jest|vitest|turbo run|p?npm (run )?test|p?npm run build|next build|tsc' \
          && flags="$flags [SPAWNS-TEST/BUILD]"
        # PostToolUse that spawns anything heavy is the pile-up risk
        if [ "$event" = "PostToolUse" ]; then
          echo "$command" | grep -qiE 'jest|vitest|test|build|tsc|eslint|stylelint' \
            && flags="$flags [POSTTOOLUSE-HEAVY: can pile up]"
        fi
        # script-file existence (first token if it looks like a path)
        first="${command%% *}"
        expanded="${first/#\~/$HOME}"
        case "$first" in
          */*|~/*)
            if [ ! -e "$expanded" ]; then flags="$flags [MISSING-SCRIPT]"
            elif [ ! -x "$expanded" ]; then flags="$flags [NOT-EXECUTABLE]"; fi
            ;;
        esac
        printf "    %-12s matcher=%-18s cmd=%s%s\n" "$event" "$matcher" "$command" "$flags"
      done
  done
  echo ""
done

# --- 4. secret-access exposure --------------------------------------------

echo "=== 4. Secret-access exposure ==="
echo "    Read-tool deny rules do NOT cover Bash; a Bash PreToolUse hook is what"
echo "    actually guards shell access to secrets. Verify both layers."
echo ""

echo "  Read-tool deny coverage (per settings file):"
for f in "${SETTINGS_FILES[@]}"; do
  [ -f "$f" ] || continue
  deny=$(jq -r '(.permissions.deny // [])[]' "$f" 2>/dev/null)
  envcov=$(echo "$deny" | grep -qiE '\.env' && echo yes || echo "NO")
  seccov=$(echo "$deny" | grep -qiE 'secret' && echo yes || echo "NO")
  printf "    .env:%-4s secrets:%-4s  %s\n" "$envcov" "$seccov" "$f"
done
echo ""

echo "  Bash secret-guard hook:"
GUARD="$HOME/.claude/hooks/block-secret-access.sh"
if [ -e "$GUARD" ]; then
  [ -x "$GUARD" ] && x="executable" || x="NOT-EXECUTABLE"
  echo "    script present ($x): $GUARD"
  wired="NO"
  for f in "${SETTINGS_FILES[@]}"; do
    [ -f "$f" ] || continue
    if jq -e --arg g "$GUARD" '
        (.hooks.PreToolUse // [])[]
        | select((.matcher // "") | test("Bash"))
        | .hooks[].command
        | test("block-secret-access")' "$f" >/dev/null 2>&1; then
      wired="yes ($f)"
    fi
  done
  echo "    wired into a Bash PreToolUse matcher: $wired"
else
  echo "    MISSING: $GUARD — Bash access to secrets is UNGUARDED"
fi
echo ""

echo "  Broad file-reading Bash commands in allow-lists (could bypass Read deny):"
hit=0
for f in "${SETTINGS_FILES[@]}"; do
  [ -f "$f" ] || continue
  risky=$(jq -r '(.permissions.allow // [])[]' "$f" 2>/dev/null \
    | grep -iE 'Bash\((cat|less|more|head|tail|strings|xxd|od|env|printenv)[ )*]' || true)
  if [ -n "$risky" ]; then
    echo "    in $f:"; echo "$risky" | sed 's/^/      /'; hit=1
  fi
done
[ "$hit" -eq 0 ] && echo "    (none — no broad file-readers allowlisted)"
echo ""

echo "######################################################################"
echo "# end of sweep — all read-only. Nothing was killed or modified."
echo "######################################################################"