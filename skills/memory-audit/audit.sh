#!/usr/bin/env bash
#
# Read-only audit of the agent memory store for the current project.
# Usage:
#   bash audit.sh          # full diagnostics report
#   bash audit.sh --dir    # print the memory dir path only (for `cd "$(... --dir)"`)
#
# Never mutates anything. Safe to run any time.

memory_dir_for_cwd() {
  echo "$HOME/.claude/projects/$(pwd | sed 's#/#-#g')/memory"
}

MEM_DIR="$(memory_dir_for_cwd)"

if [ "${1:-}" = "--dir" ]; then
  echo "$MEM_DIR"
  exit 0
fi

if [ ! -d "$MEM_DIR" ]; then
  echo "No memory dir found at: $MEM_DIR"
  echo ""
  echo "Other projects with memory dirs:"
  ls -d "$HOME/.claude/projects/"*/memory 2>/dev/null | sed 's#^#  #' || echo "  (none)"
  exit 0
fi

cd "$MEM_DIR" || exit 1

files() { ls -1 *.md 2>/dev/null | grep -v '^MEMORY.md$'; }

echo "=== Memory dir ==="
echo "$MEM_DIR"
echo ""

echo "=== Index size (MEMORY.md — re-sent every session) ==="
if [ -f MEMORY.md ]; then
  printf "%s words, %s bytes\n" "$(wc -w < MEMORY.md | tr -d ' ')" "$(wc -c < MEMORY.md | tr -d ' ')"
else
  echo "WARNING: no MEMORY.md index file present"
fi
echo ""

echo "=== File counts ==="
printf "memory files (excl. index): %s\n" "$(files | wc -l | tr -d ' ')"
echo "by prefix:"
files | sed 's/_.*//' | sort | uniq -c | sort -rn | sed 's/^/  /'
echo ""

echo "=== Orphans (file not linked from MEMORY.md) ==="
orphan=0
for f in $(files); do
  if ! grep -q "($f)" MEMORY.md 2>/dev/null; then echo "  $f"; orphan=1; fi
done
[ "$orphan" -eq 0 ] && echo "  (none)"
echo ""

echo "=== Dangling [[links]] (slug matches no file name or frontmatter name:) ==="
# Valid targets = filenames without .md  +  every `name:` frontmatter value.
valid=$(mktemp)
{
  for f in *.md; do echo "${f%.md}"; done
  grep -h '^name:' *.md 2>/dev/null | sed 's/^name:[[:space:]]*//; s/^["'"'"']//; s/["'"'"']$//'
} | sort -u > "$valid"
dangling=0
for link in $(grep -ohE '\[\[[A-Za-z0-9_-]+\]\]' *.md 2>/dev/null | sed 's/\[\[//; s/\]\]//' | sort -u); do
  if ! grep -qxF "$link" "$valid"; then echo "  [[$link]]"; dangling=1; fi
done
rm -f "$valid"
[ "$dangling" -eq 0 ] && echo "  (none)"
echo ""

echo "=== Broken index entries (MEMORY.md links to a missing file) ==="
broken=0
for target in $(grep -oE '\]\([A-Za-z0-9_.-]+\.md\)' MEMORY.md 2>/dev/null | sed 's/](//; s/)//'); do
  if [ ! -f "$target" ]; then echo "  $target"; broken=1; fi
done
[ "$broken" -eq 0 ] && echo "  (none)"
echo ""

echo "=== Largest files (potential merge targets / bloat) ==="
files | xargs wc -w 2>/dev/null | grep -v ' total$' | sort -rn | head -10 \
  | awk '{printf "  %5s words  %s\n", $1, $2}'