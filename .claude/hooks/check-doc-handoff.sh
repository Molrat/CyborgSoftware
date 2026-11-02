#!/usr/bin/env bash
# PreToolUse guard on `git commit`: a new feature must not land without the
# architecture docs that describe it.
#
# Root CLAUDE.md rule 4 — a change is not finished until the docs say what it
# decided — is the only thing carrying a decision from one slice to the next,
# because the next slice starts with none of this conversation's context. It is
# the rule that fails silently: a feature ships, the docs still describe the
# system without it, and the next cold agent builds on the wrong picture.
#
# Asks rather than denies. The judgement call is the user's; the point is that
# it gets made, not skipped. Always exits 0.
set -u

cat >/dev/null   # drain stdin; the staged index is the input that matters

added=$(git diff --cached --name-status --diff-filter=A 2>/dev/null | awk '{print $2}')
[ -n "$added" ] || exit 0

# Does this path exist in HEAD already? Used to tell a genuinely new directory
# from another file dropped into one that is already documented.
in_head() { git rev-parse --verify --quiet "HEAD:$1" >/dev/null 2>&1; }

new_areas=""
note() {
  case "$new_areas" in
    *"$1"*) ;;                       # already collected
    *) new_areas="${new_areas}${1} " ;;
  esac
}

while IFS= read -r f; do
  [ -n "$f" ] || continue
  case "$f" in

    # A new .csproj under api/src/<Feature>/ is a new backend feature slice.
    containers/*/api/src/*/*.csproj)
      note "$(printf '%s' "$f" | sed -E 's#^containers/[^/]+/api/src/([^/]+)/.*#\1#')"
      ;;

    # Frontend: a new *directory*, not a new file in an existing one. Adding a
    # component to an existing feature folder is routine and must not prompt;
    # adding a new feature folder or a whole new sibling under src/ is not.
    containers/frontend/src/features/*/*)
      d=$(printf '%s' "$f" | sed -E 's#^(containers/frontend/src/features/[^/]+)/.*#\1#')
      in_head "$d" || note "${d#containers/frontend/src/}"
      ;;
    containers/frontend/src/*/*)
      d=$(printf '%s' "$f" | sed -E 's#^(containers/frontend/src/[^/]+)/.*#\1#')
      in_head "$d" || note "${d#containers/frontend/src/}"
      ;;
  esac
done <<EOF
$added
EOF

[ -n "$new_areas" ] || exit 0

# Did the same commit touch the architecture docs?
git diff --cached --name-only 2>/dev/null | grep -qE '^docs/architecture/' && exit 0

areas=$(printf '%s' "$new_areas" | sed 's/[[:space:]]*$//')

printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"This commit adds a new feature area (%s) but changes nothing under docs/architecture/. CLAUDE.md rule 4: a slice is finished when the docs say what it decided, not when it compiles. Expected alongside it: the area added to 02-backend-structure.md or 03-frontend-structure.md, and any status marker it moved in README.md Where the system stands. Commit anyway only if the docs genuinely need no change."}}\n' "$areas"
