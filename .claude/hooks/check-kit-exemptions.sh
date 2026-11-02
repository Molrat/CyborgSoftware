#!/usr/bin/env bash
# PreToolUse guard on `git commit`: the design system's exemptions only shrink,
# and its checks are not loosened quietly (docs/architecture/design-system.md).
#
# containers/frontend/kit-exemptions.json lists screen files that predate the
# kit or were exempted by the user's decision (each recorded in docs/DEBT.md). A file leaves it when it moves onto the kit.
# Adding one back — or weakening eslint.config.js / stylelint.config.js — is
# the easiest way for an agent to make a failing check pass without building
# from the kit, and it would look like any other config change in review.
#
# Asks rather than denies: the user may have a reason. The point is that a
# person decides it. Always exits 0.
set -u

cat >/dev/null   # drain stdin; the staged index is the input that matters

fe=containers/frontend
in_head() { git rev-parse --verify --quiet "HEAD:$1" >/dev/null 2>&1; }

why=""

if in_head "$fe/kit-exemptions.json"; then
  # Entries, not lines: JSON's trailing commas make an untouched entry look changed.
  entries() { grep -oE '"src/[^"]+"' | tr -d '"' | sort -u; }
  before=$(git show "HEAD:$fe/kit-exemptions.json" 2>/dev/null | entries)
  after=$(git show ":$fe/kit-exemptions.json" 2>/dev/null | entries)
  grown=$(comm -13 <(printf '%s\n' "$before") <(printf '%s\n' "$after") | grep . | tr '\n' ' ')
  [ -n "$grown" ] && why="${why}It adds to kit-exemptions.json: ${grown}— the list only shrinks; a screen is moved onto the kit instead. "
fi

for config in eslint.config.js stylelint.config.js; do
  if in_head "$fe/$config" && git diff --cached --quiet -- "$fe/$config" 2>/dev/null; then :; elif in_head "$fe/$config"; then
    why="${why}It changes $fe/$config, which holds the design-system checks. "
  fi
done

[ -n "$why" ] || exit 0

reason="${why}Commit only if the user has agreed to this (docs/architecture/design-system.md, docs/DEBT.md)."
reason=$(printf '%s' "$reason" | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"%s"}}\n' "$reason"
