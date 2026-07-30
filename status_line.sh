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
e=$(printf '\033')
cyan="${e}[36m"; grn="${e}[32m"
yel="${e}[33m"; red="${e}[31m"; rst="${e}[0m"

parts=()

# <model> with <effort> effort
if [ -n "$model" ]; then
  if [ -n "$effort" ]; then
    parts+=("${cyan}${model}${rst} with ${cyan}${effort}${rst} effort")
  else
    parts+=("${cyan}${model}${rst}")
  fi
fi

# <n>% of context used
case "$used" in
  ''|*[!0-9.eE+-]*) u=0 ;;
  *) u=$(printf '%.0f' "$used" 2>/dev/null) || u=0 ;;
esac
[ -z "$u" ] && u=0
if [ "$u" -ge 75 ] 2>/dev/null; then c="$red"
elif [ "$u" -ge 50 ] 2>/dev/null; then c="$yel"
else c="$grn"
fi
parts+=("${c}${u}%${rst} of context used")

# $<usd spent> spent
case "$cost" in
  ''|*[!0-9.eE+-]*) s='0.00' ;;
  *) s=$(printf '%.2f' "$cost" 2>/dev/null) || s='0.00' ;;
esac
[ -z "$s" ] && s='0.00'
parts+=("${cyan}\$${s}${rst} spent")

# working in "<directory>"
[ -n "$cwd" ] && parts+=("working in \"${cyan}${cwd}${rst}\"")

# on branch "<branch>"
[ -n "$branch" ] && parts+=("on branch \"${cyan}${branch}${rst}\"")

# join with middle-dot separator
# U+00B7
sep=" $(printf '\302\267') "
out=''
for p in "${parts[@]}"; do
  if [ -z "$out" ]; then out="$p"; else out="${out}${sep}${p}"; fi
done
printf '%s\n' "$out"
