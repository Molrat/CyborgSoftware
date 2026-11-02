#!/usr/bin/env bash
# PreToolUse guard on `git commit`: docs/TESTING.md must not describe a test
# suite that no longer exists.
#
# The rot this exists for is real: in the project this setup came from, the doc
# once claimed a tenth of the tests the tree held, and named a test project that
# had existed for days as the largest gap in the system. Nothing caught it
# because check-doc-handoff.sh only watches for new *feature* directories, and a
# test project is neither a feature nor a new `src/` area.
#
# Why that mattered more than a wrong number: the `tester` agent starts cold and
# reads TESTING.md *first*, to decide which layer owns a behaviour and what is
# already covered. A doc claiming a layer is empty sends it to write tests that
# exist, or to skip a layer that is real. The verifier and the thing it verifies
# drifted apart silently — which is the failure class this repo keeps hitting.
#
# Asks rather than denies, like the doc-handoff guard: the judgement is the
# user's, the point is that it gets made. Prints the corrected line so the fix
# is a paste. Always exits 0 — a linter that crashes must not derail a commit.
set -u

cat >/dev/null   # the staged index is the input that matters, not the payload

root=${CLAUDE_PROJECT_DIR:-.}
doc="$root/docs/TESTING.md"
[ -f "$doc" ] || exit 0

# Only speak up on commits that actually touch tests. A doc-only or backend-only
# commit has no business being told about test counts.
staged=$(git diff --cached --name-only 2>/dev/null)
[ -n "$staged" ] || exit 0

printf '%s\n' "$staged" | grep -qE '^tests/|\.test\.ts$|conformance/.*\.json$' || exit 0

# Already updating the doc in this very commit? Then it is being maintained.
printf '%s\n' "$staged" | grep -qx 'docs/TESTING.md' && exit 0

# --- count the tree -------------------------------------------------------
# Definition of "a test", fixed here and mirrored in the doc's inventory
# comment: one .NET [Fact]/[Theory] method, one frontend it()/test() block, or
# one browser-layer test() in tests/browser/journeys/.
# [Theory] cases expand at run time, so these are method counts, not run counts.
count_dotnet() {
  [ -d "$root/$1" ] || { echo 0; return; }
  grep -rh --include=*.cs -e '\[Fact\]' -e '\[Theory\]' "$root/$1" 2>/dev/null | wc -l | tr -d ' '
}

unit=$(count_dotnet tests/unit)
component=$(count_dotnet tests/component)
e2e=$(count_dotnet tests/e2e)

frontend=0
if [ -d "$root/containers/frontend/src" ]; then
  frontend=$(grep -rhE --include=*.test.ts '^[[:space:]]*(it|test)\(' \
    "$root/containers/frontend/src" 2>/dev/null | wc -l | tr -d ' ')
fi

browser=0
if [ -d "$root/tests/browser/journeys" ]; then
  browser=$(grep -rhE --include=*.spec.ts '^[[:space:]]*test\(' \
    "$root/tests/browser/journeys" 2>/dev/null | wc -l | tr -d ' ')
fi

# The project roster: a new or deleted test project changes what the doc's
# layer tables name, which no count can express. The .NET layers only:
# tests/browser/ is one npm package, and its folders are not projects.
projects=$( { ls -d "$root"/tests/unit/*/ "$root"/tests/component/*/ "$root"/tests/e2e/*/ 2>/dev/null | sed 's#/$##; s#.*/##'; } | sort | tr '\n' ',' )
projects=${projects%,}

actual="unit=$unit component=$component e2e=$e2e frontend=$frontend browser=$browser projects=$projects"

# --- compare against what the doc claims ----------------------------------
claimed=$(sed -n 's/^<!-- test-inventory: \(.*\) -->$/\1/p' "$doc" | head -1)

if [ -z "$claimed" ]; then
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"docs/TESTING.md has no <!-- test-inventory: ... --> line, so nothing can tell when its counts go stale. Add this line under the Current state paragraph:\\n\\n<!-- test-inventory: %s -->\\n\\nand make the prose agree with it."}}\n' "$actual"
  exit 0
fi

get() { printf '%s' "$1" | tr ' ' '\n' | sed -n "s/^$2=//p"; }

c_unit=$(get "$claimed" unit);           c_component=$(get "$claimed" component)
c_e2e=$(get "$claimed" e2e);             c_frontend=$(get "$claimed" frontend)
c_browser=$(get "$claimed" browser)
c_projects=$(get "$claimed" projects)

drifted=""
note_drift() { drifted="${drifted}  - $1\\n"; }

# Tolerance: a layer may drift by 5 methods before this fires. Tight enough
# that the numbers stay true, loose enough that a two-test commit is silent —
# a guard that nags on every commit gets worked around, and then guards nothing.
check_count() {
  local name=$1 claim=$2 real=$3
  case "$claim" in ''|*[!0-9]*) note_drift "$name: doc claims nothing parseable; tree has $real"; return ;; esac
  local d=$(( claim > real ? claim - real : real - claim ))
  [ "$d" -gt 5 ] && note_drift "$name: doc says $claim, tree has $real"
  return 0
}

check_count "unit"      "$c_unit"      "$unit"
check_count "component" "$c_component" "$component"
check_count "e2e"       "$c_e2e"       "$e2e"
check_count "frontend"  "$c_frontend"  "$frontend"
check_count "browser"   "$c_browser"   "$browser"

# Any roster change at all matters — no tolerance here.
if [ "$c_projects" != "$projects" ]; then
  note_drift "test projects changed: doc knows [$c_projects], tree has [$projects]"
fi

[ -n "$drifted" ] || exit 0

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"docs/TESTING.md no longer describes this test suite:\\n\\n%s\\nThe cold `tester` agent reads that doc first to decide which layer owns a behaviour and what is already covered, so a stale one sends it to write tests that exist or skip a layer that is real. Update the layer tables, the Current state line, and the *What this system does not cover yet* section (a gap that has since been closed belongs out of it), then replace the inventory line with:\\n\\n<!-- test-inventory: %s -->\\n\\nCommit anyway only if the doc genuinely already says all of this."}}\n' "$drifted" "$actual"
