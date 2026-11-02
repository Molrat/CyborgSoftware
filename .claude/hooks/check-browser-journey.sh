#!/usr/bin/env bash
# PreToolUse guard on `git commit`: a new screen must not land without the
# browser layer hearing about it.
#
# /feature-slice step 5 adds a journey in tests/browser/journeys/ when a slice
# adds a path a person must be able to walk, and step 6 looks at the screen in
# the browser (/look). Both are instructions, and instructions get skipped by
# a busy agent; this is the one place the rule is checked rather than asked.
#
# A "new screen" is what the staged diff can see without judgement:
#   - a new *Page.vue anywhere under containers/frontend/src/pages/
#   - a new directory under containers/frontend/src/features/
#   - a new `path:` line in the router (the route table is router/routes.ts)
# A commit carrying any of those and no change under tests/browser/journeys/
# is stopped and asked about — not denied: a screen that is genuinely reached
# only through an existing journey's path needs no new one, and that judgement
# is the user's. Always exits 0.
set -u

cat >/dev/null   # drain stdin; the staged index is the input that matters

staged=$(git diff --cached --name-status 2>/dev/null)
[ -n "$staged" ] || exit 0

# Already touching the journeys? Then the layer is being kept up.
git diff --cached --name-only 2>/dev/null | grep -q '^tests/browser/journeys/' && exit 0

in_head() { git rev-parse --verify --quiet "HEAD:$1" >/dev/null 2>&1; }

screens=""
note() {
  case "$screens" in
    *"$1"*) ;;
    *) screens="${screens}${1} " ;;
  esac
}

while IFS="$(printf '\t')" read -r status path _; do
  [ "$status" = "A" ] || continue
  case "$path" in
    containers/frontend/src/pages/*Page.vue)
      note "${path#containers/frontend/src/}"
      ;;
    containers/frontend/src/features/*/*)
      d=$(printf '%s' "$path" | sed -E 's#^(containers/frontend/src/features/[^/]+)/.*#\1#')
      in_head "$d" || note "${d#containers/frontend/src/}/"
      ;;
  esac
done <<EOF
$staged
EOF

routes=$(git diff --cached -U0 -- containers/frontend/src/router/routes.ts containers/frontend/src/router/index.ts 2>/dev/null \
  | grep -E "^\+[^+].*path: *'" | sed -E "s/.*path: *'([^']*)'.*/\1/" | tr '\n' ' ')
[ -n "$routes" ] && note "route ${routes% }"

[ -n "$screens" ] || exit 0
screens=$(printf '%s' "$screens" | sed 's/[[:space:]]*$//' | sed 's/"/\\"/g')

# The reason is read by the user in the approval prompt, so it is written for
# them (/talk-to-human): purpose, consequence, recommendation; the pointers
# for the agent come last.
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"Check before saving this work: it adds a new screen, but no saved browser test was added or changed. Without one, nothing will notice if this screen later stops working, until someone walks into it by hand. Recommended: say no, and ask the AI to add the browser test and to look at the screen in the app first. Say yes only if the AI has explained that an existing browser test already walks through this screen, or that this is not yet the finished version. (For the agent: new screen %s; /feature-slice steps 5 and 6, /look.)"}}\n' "$screens"
