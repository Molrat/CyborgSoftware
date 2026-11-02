#!/usr/bin/env bash
# Regenerate the sub-phase table in phases.md from the frontmatter in phases/.
#
# The table carries state, and state lives in exactly one place — each
# sub-phase's own file (docs/roadmap/README.md). A hand-maintained second copy
# drifts from the first, so the table is generated instead: run this after any
# state change, and /continue runs it whenever it moves a sub-phase between
# states.
#
# Rewrites only the lines between the INDEX markers. Everything else in
# phases.md is prose and is never touched.
set -eu

root=${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}
cd "$root/docs/roadmap"

fm() { sed -n "/^---$/,/^---$/p" "$1" | sed -n "s/^$2: *//p" | head -1 | sed 's/^"//; s/"$//'; }

tmp=$(mktemp)
{
  printf '| # | Sub-phase | State |\n|---|---|---|\n'
  # sort -V puts 2.3.7 before 2.4.1 and 2.4.7 before 2.5
  for f in $(ls phases/*.md 2>/dev/null | sort -V); do
    id=$(fm "$f" id); title=$(fm "$f" title); state=$(fm "$f" state)
    [ -n "$id" ] || continue
    case "$state" in
      COMPLETE) mark="$state" ;;
      BUILT)    mark="**$state** — gate not walked" ;;
      BUILDING) mark="**$state**" ;;
      *)        mark="$state" ;;
    esac
    printf '| `%s` | [%s](%s) | %s |\n' "$id" "$title" "$f" "$mark"
  done
  printf '\n'
  for s in BUILT BUILDING READY DRAFT; do
    n=$(grep -l "^state: $s$" phases/*.md 2>/dev/null | wc -l | tr -d ' ')
    [ "$n" -gt 0 ] && printf '%s: %s · ' "$s" "$n"
  done
  printf 'COMPLETE: %s\n' "$(grep -l '^state: COMPLETE$' phases/*.md 2>/dev/null | wc -l | tr -d ' ')"
} > "$tmp"

awk -v f="$tmp" '
  /^<!-- INDEX:START -->$/ { print; while ((getline l < f) > 0) print l; skip=1; next }
  /^<!-- INDEX:END -->$/   { skip=0 }
  !skip { print }
' phases.md > phases.md.new && mv phases.md.new phases.md
rm -f "$tmp"
echo "phases.md index regenerated from phases/*.md"
