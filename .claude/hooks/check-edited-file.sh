#!/usr/bin/env bash
# PostToolUse lint: the rules in docs/CODING-STANDARDS.md that a machine can
# check, applied to the file that was just written.
#
# Reports violations back to Claude rather than blocking the write — these are
# quality rules, not destructive mistakes (that is the migration guard's job).
# Always exits 0: a linter that crashes must not derail the session.
set -u

payload=$(cat)

path=$(printf '%s' "$payload" \
  | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
  | head -1 \
  | tr '\\' '/' \
  | tr -s '/')

[ -n "$path" ] || exit 0
[ -f "$path" ] || exit 0

case "$path" in
  */node_modules/*|*/bin/*|*/obj/*|*/dist/*) exit 0 ;;
esac

problems=""
add() { problems="${problems}- $1
"; }

name=${path##*/}
lines=$(wc -l < "$path" | tr -d ' ')

case "$path" in

  # --- stored functions: db-procedures/procedures/<table>/sp_<table>_<verb>.sql
  */db-procedures/procedures/*.sql)
    grep -qi 'GRANT[[:space:]]\+EXECUTE' "$path" \
      || add "No \`GRANT EXECUTE ... TO \${APP_USER}\`. Every function file ends with its own grant — the app user holds execute rights and no DDL rights, so without it the endpoint fails at runtime, not at deploy."

    if grep -v '^[[:space:]]*--' "$path" | grep -qi 'SELECT[[:space:]]\+\*'; then
      add "Uses \`SELECT *\`. Functions returning a table need explicit column lists (docs/architecture/04-persistence.md)."
    fi

    table=$(basename "$(dirname "$path")")
    case "$name" in
      sp_${table}_*.sql) ;;
      *) add "Named \`$name\` but sits in \`procedures/$table/\`. Convention is \`sp_<table>_<verb>.sql\` in the folder named for its table." ;;
    esac
    ;;

  # --- C#
  *.cs)
    case "$path" in
      *.Controllers/*)
        grep -q 'BadRequest([[:space:]]*new' "$path" \
          && add "Returns \`BadRequest(new { ... })\`. That bypasses the error envelope the frontend parses — throw a typed \`ApplicationError\` (\`ValidationError\`, \`NotFoundError\`, \`ForbiddenError\`) and let \`ExceptionHandlingMiddleware\` map it."
        ;;
    esac
    [ "$lines" -gt 200 ] && add "$lines lines. Keep files under 200 (docs/CODING-STANDARDS.md); split by responsibility rather than trimming."
    ;;

  # --- TypeScript / Vue
  *.ts|*.vue)
    if grep -nE '(:[[:space:]]*any\b|as[[:space:]]+any\b|<any>)' "$path" | grep -qv '^\s*//'; then
      add "Uses \`any\`. Use \`unknown\` plus a narrowing check where the type genuinely is not known (docs/CODING-STANDARDS.md)."
    fi
    [ "$lines" -gt 200 ] && add "$lines lines. Keep files under 200 (docs/CODING-STANDARDS.md); split by responsibility rather than trimming."
    ;;

  # --- CSS: only the design-system checks below apply.
  *.css) ;;

  *) exit 0 ;;
esac

# --- The design system (docs/architecture/design-system.md §4): the same
# ESLint and Stylelint rules as `npm run lint` and the deploy build, on the
# frontend file just written, so a screen built outside src/kit/ is caught at
# the edit rather than at the commit. Files on kit-exemptions.json are skipped
# by both configs.
case "$path" in
  */containers/frontend/src/*)
    fe="${path%%/containers/frontend/src/*}/containers/frontend"
    rel="src/${path#*/containers/frontend/src/}"
    if [ -x "$fe/node_modules/.bin/eslint" ]; then
      case "$rel" in
        *.ts|*.vue)
          if ! out=$(cd "$fe" && node_modules/.bin/eslint --no-warn-ignored --no-color "$rel" 2>&1); then
            add "Design-system check (ESLint) — build it from src/kit/ (docs/architecture/design-system.md):
$out"
          fi
          ;;
      esac
      case "$rel" in
        *.vue|*.css)
          if ! out=$(cd "$fe" && node_modules/.bin/stylelint --allow-empty-input --formatter unix "$rel" 2>&1); then
            add "Design-system check (Stylelint) — use the tokens in src/styles/base.css and the kit (docs/architecture/design-system.md):
$out"
          fi
          ;;
      esac
    fi
    ;;
esac

[ -n "$problems" ] || exit 0

# JSON-escape: backslashes, quotes, then newlines.
reason=$(printf '%s' "$problems" \
  | sed 's/\\/\\\\/g; s/"/\\"/g' \
  | sed ':a;N;$!ba;s/\n/\\n/g')

printf '{"decision":"block","reason":"%s in %s:\\n%s"}\n' "Coding-standards violations" "$name" "$reason"
