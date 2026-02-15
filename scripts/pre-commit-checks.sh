#!/bin/bash

# beforeShellExecution hook for git commit checks.
# Returns JSON only on stdout.

allow() {
  printf '%s\n' '{"permission":"allow"}'
  exit 0
}

deny() {
  local user_message="$1"
  local agent_message="$2"
  printf '%s\n' "{\"permission\":\"deny\",\"user_message\":\"${user_message}\",\"agent_message\":\"${agent_message}\"}"
  exit 0
}

HOOK_INPUT="$(cat)"
if [ -z "$HOOK_INPUT" ]; then
  allow
fi

ONE_LINE_INPUT="$(printf '%s' "$HOOK_INPUT" | tr -d '\n')"
COMMAND="$(
  printf '%s' "$ONE_LINE_INPUT" \
    | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
)"

# Extra safety guard beyond matcher.
if [[ ! "$COMMAND" =~ (^|[[:space:]])git[[:space:]]+commit($|[[:space:]]) ]]; then
  allow
fi

if [ ! -d "convex" ]; then
  allow
fi

# Block Date.now() in query functions.
DATE_NOW_IN_QUERIES="$(grep -r "Date\.now()" convex/ --include="*.ts" --include="*.js" | grep -B 5 "query({" | grep "Date\.now()" || true)"
if [ -n "$DATE_NOW_IN_QUERIES" ]; then
  deny \
    "Commit blocked: found Date.now() inside/near Convex query functions." \
    "beforeShellExecution blocked this git commit because Date.now() was detected near query({}) in convex/. Queries should be deterministic for reactivity. Use server-generated timestamps in writes or pass time as an argument."
fi

# Block .filter() chained from Convex db.query().
FILTER_ON_QUERIES="$(grep -r "\.query(.*)\s*\.filter(" convex/ --include="*.ts" --include="*.js" || true)"
if [ -n "$FILTER_ON_QUERIES" ]; then
  deny \
    "Commit blocked: found .filter() on Convex db.query() calls." \
    "beforeShellExecution blocked this git commit because .filter() was detected on db.query() in convex/. Prefer indexed access patterns such as .withIndex() for performance and correctness."
fi

allow