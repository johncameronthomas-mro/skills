#!/usr/bin/env bash

raw=$(cat)
[ -z "$raw" ] && exit 0

# JSON extraction
# Uses jq when available; otherwise falls back to grep/sed.
if command -v jq >/dev/null 2>&1; then
  _get() { printf '%s' "$raw" | jq -r "$1 // empty" 2>/dev/null; }
  model=$(_get '.model.display_name')
  effort=$(_get '.effort.level')
  used=$(_get '.context_window.used_percentage')
  cost=$(_get '.cost.total_cost_usd')
  cwd=$(_get '.workspace.current_dir')
  [ -z "$cwd" ] && cwd=$(_get '.cwd')
else
  flat=$(printf '%s' "$raw" | tr -d '\n')
  _str() {
    printf '%s' "$flat" \
      | grep -o "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
      | head -1 | sed -e "s/.*:[[:space:]]*\"//" -e 's/"$//'
  }
  _num() {
    printf '%s' "$flat" \
      | grep -o "\"$1\"[[:space:]]*:[[:space:]]*-\{0,1\}[0-9][0-9.eE+-]*" \
      | head -1 | sed -e "s/.*:[[:space:]]*//"
  }
  model=$(_str display_name)
  effort=$(_str level)
  used=$(_num used_percentage)
  cost=$(_num total_cost_usd)
  cwd=$(_str current_dir)
  [ -z "$cwd" ] && cwd=$(_str cwd)
fi

# current git branch (if inside a repo)
branch=''
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# ANSI colors
escape=$(printf '\033')
accent="${escape}[34m"
green="${escape}[32m"
yellow="${escape}[33m"
red="${escape}[31m"
reset="${escape}[0m"

parts=()

# <model> with <effort> effort
if [ -n "$model" ]; then
  if [ -n "$effort" ]; then
    parts+=("${accent}${model}${reset} with ${accent}${effort}${reset} effort")
  else
    parts+=("${accent}${model}${reset}")
  fi
fi

# <n>% of context used
case "$used" in
  ''|*[!0-9.eE+-]*) u=0 ;;
  *) u=$(printf '%.0f' "$used" 2>/dev/null) || u=0 ;;
esac
[ -z "$u" ] && u=0
if [ "$u" -ge 75 ] 2>/dev/null; then color="$red"
elif [ "$u" -ge 50 ] 2>/dev/null; then color="$yellow"
else color="$green"
fi
parts+=("${color}${u}%${reset} of context used")

# $<usd spent> spent
case "$cost" in
  ''|*[!0-9.eE+-]*) s='0.00' ;;
  *) s=$(printf '%.2f' "$cost" 2>/dev/null) || s='0.00' ;;
esac
[ -z "$s" ] && s='0.00'
parts+=("${accent}\$${s}${reset} spent")

# working in "<directory>"
[ -n "$cwd" ] && parts+=("working in \"${accent}${cwd}${reset}\"")

# on branch "<branch>"
[ -n "$branch" ] && parts+=("on branch \"${accent}${branch}${reset}\"")

# join with middle-dot separator
# U+00B7
separator=" $(printf '\302\267') "
out=''
for p in "${parts[@]}"; do
  if [ -z "$out" ]; then out="$p"; else out="${out}${separator}${p}"; fi
done
printf '%s\n' "$out"
