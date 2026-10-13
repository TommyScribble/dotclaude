#!/bin/bash

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0

echo "$FILE_PATH" | grep -qE '(/utils/build/sentry|/instrumentation(-client)?|/sentry\.(server|edge|client)\.config)\.(ts|js|mjs)$' || exit 0

SAMPLING='[Ss][Aa][Mm][Pp][Ll]|(^|[^0-9A-Za-z_.])(0?\.[0-9]+|1\.0+)([^0-9]|$)'

CURRENT=$([ -f "$FILE_PATH" ] && cat "$FILE_PATH")

NEW=$(echo "$INPUT" | python3 -I -c '
import json, sys
payload = json.load(sys.stdin)
tool = payload.get("tool_name")
tool_input = payload.get("tool_input", {})
current = open(tool_input["file_path"]).read() if tool != "Write" else ""
if tool == "Write":
    print(tool_input.get("content", ""), end="")
elif tool in ("Edit", "MultiEdit"):
    edits = tool_input.get("edits") or [tool_input]
    for edit in edits:
        count = -1 if edit.get("replace_all") else 1
        current = current.replace(edit.get("old_string", ""), edit.get("new_string", ""), count)
    print(current, end="")
else:
    sys.exit(1)
' 2>/dev/null) || exit 0

HUNKS=$(diff -U1 <(printf '%s\n' "$CURRENT") <(printf '%s\n' "$NEW") | grep -vE '^(@@|---|\+\+\+)')

SAMPLING_LINES=$(echo "$HUNKS" | grep -E "$SAMPLING")

[ -z "$SAMPLING_LINES" ] && exit 0

REASON="This changes Sentry sampling in $(basename "$FILE_PATH"), which spends quota. Tommy signs these off. Say what the change does to event volume and whether a cheaper option exists. Changed lines:
$(echo "$SAMPLING_LINES" | head -10)"

jq -n --arg reason "$REASON" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "ask",
    permissionDecisionReason: $reason
  }
}'

exit 0
