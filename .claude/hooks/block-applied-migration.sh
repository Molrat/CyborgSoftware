#!/usr/bin/env bash
# PreToolUse guard: refuse edits to an already-applied migration.
#
# Migrations are append-only (docs/CODING-STANDARDS.md, "SQL"). Editing one that
# has already run is silent and unrecoverable: every database that applied it
# never sees the change, so environments diverge with nothing in the schema
# history to show it. Creating a NEW V###__*.sql is untouched by this guard.
#
# Reads the PreToolUse payload on stdin, emits a deny decision, and always exits
# 0 — a guard that crashes must not block unrelated edits.
set -u

payload=$(cat)

# No jq on the team's Windows boxes, so pull the first file_path out with sed.
# Every backslash becomes a forward slash and runs are squeezed, which handles
# JSON's doubled backslashes and a raw Windows path identically — a separator is
# never data, so this cannot corrupt a real path.
path=$(printf '%s' "$payload" \
  | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | head -1 \
  | tr '\\' '/' \
  | tr -s '/')

[ -n "$path" ] || exit 0

case "$path" in
  */db-migrations/migrations/V*.sql) ;;
  *) exit 0 ;;
esac

# Not yet on disk means a new migration. That is the sanctioned way to change
# the schema, so let it through.
[ -f "$path" ] || exit 0

name=${path##*/}
printf '%s\n' "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$name is an applied migration, and migrations are append-only (docs/CODING-STANDARDS.md). Editing it changes nothing in any database that already ran it, so environments silently diverge. Add the next V###__description.sql instead. If this migration has genuinely never been applied anywhere, the user has to say so explicitly.\"}}"
