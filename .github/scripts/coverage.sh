#!/usr/bin/env bash
# Compute in-scope line coverage from an lcov tracefile.
#
# Exclusion patterns are read from a config file rather than hardcoded here, so
# the CI definition holds no knowledge of the lib/ layout. Emits `coverage` and
# `lines` to $GITHUB_OUTPUT when running under Actions.
#
# Usage: coverage.sh [lcov-file] [exclude-file]
set -euo pipefail

LCOV_FILE="${1:-coverage/lcov.info}"
EXCLUDE_FILE="${2:-.github/coverage-exclude.txt}"

coverage="0"
lines=""

if [[ -f "$LCOV_FILE" ]]; then
  patterns=()
  if [[ -f "$EXCLUDE_FILE" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      line="${line%%#*}"                                # strip comments
      line="${line#"${line%%[![:space:]]*}"}"           # strip leading space
      line="${line%"${line##*[![:space:]]}"}"           # strip trailing space
      [[ -n "$line" ]] && patterns+=("$line")
    done <"$EXCLUDE_FILE"
  fi

  if ((${#patterns[@]} > 0)); then
    # --ignore-errors unused: a pattern matching nothing is not a failure,
    # otherwise deleting an excluded file would break the build.
    lcov --remove "$LCOV_FILE" "${patterns[@]}" \
      -o "$LCOV_FILE" --ignore-errors unused
  fi

  summary="$(lcov --summary "$LCOV_FILE" 2>&1)"
  coverage="$(grep -oP 'lines.*: \K[0-9.]+(?=%)' <<<"$summary" || echo "0")"
  lines="$(grep -oP 'lines.*\(\K[0-9]+ of [0-9]+(?= lines\))' <<<"$summary" || echo "")"
fi

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "coverage=$coverage" >>"$GITHUB_OUTPUT"
  echo "lines=$lines" >>"$GITHUB_OUTPUT"
fi

echo "Coverage: ${coverage}% ${lines:+($lines lines)}"
