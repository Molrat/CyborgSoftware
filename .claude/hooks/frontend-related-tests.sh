#!/usr/bin/env bash
# PostToolUse: run the Vitest tests related to a just-edited frontend source
# file. Catches breakage in seconds instead of at the next full run.
#
# No-ops unless the path is frontend source, so it costs nothing on backend or
# doc edits. Always exits 0; a failing run is reported back as feedback.
set -u

payload=$(cat)

path=$(printf '%s' "$payload" \
  | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | head -1 \
  | tr '\\' '/' \
  | tr -s '/')

[ -n "$path" ] || exit 0

case "$path" in
  */containers/frontend/src/*.ts|*/containers/frontend/src/*.vue) ;;
  containers/frontend/src/*.ts|containers/frontend/src/*.vue) ;;
  *) exit 0 ;;
esac
case "$path" in */node_modules/*) exit 0 ;; esac

root=${CLAUDE_PROJECT_DIR:-.}
fe="$root/containers/frontend"
[ -d "$fe/node_modules/.bin" ] || exit 0

# vitest wants a path it can resolve from the frontend root.
rel=${path##*containers/frontend/}

out=$(cd "$fe" && ./node_modules/.bin/vitest related --run "$rel" 2>&1)
status=$?

[ "$status" -eq 0 ] && exit 0

# Tail only — the head of a vitest failure is banner noise.
tail=$(printf '%s' "$out" | tail -40 \
  | sed 's/\\/\\\\/g; s/"/\\"/g' \
  | sed ':a;N;$!ba;s/\n/\\n/g')

printf '{"decision":"block","reason":"Vitest tests related to %s are failing:\\n\\n%s"}\n' "${path##*/}" "$tail"
