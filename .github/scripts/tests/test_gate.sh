#!/usr/bin/env bash
# The step that fails the job on results: tests must pass and coverage must
# meet the gate.
#
# Used by UnitAndWidgetTesting.yml. Each reason is its own ::error::
# annotation, so when both fail, both show. The coverage rule matches
# test_summary.py exactly: covered lines must reach ceil(MIN_COVERAGE% of all
# lines), so the comment and the gate cannot disagree.
#
# Reads: TESTS_OUTCOME (the test step's outcome), MIN_COVERAGE, and when
#        earlier steps set them COVERAGE_COVERED, COVERAGE_TOTAL, TESTS_FAILED,
#        TESTS_FILE_ERRORS and TESTS_UNFINISHED
set -euo pipefail

covered=${COVERAGE_COVERED:-}
total=${COVERAGE_TOTAL:-}

ok=1
if [ "$TESTS_OUTCOME" != success ]; then
  failed=${TESTS_FAILED:-0}
  broken=${TESTS_FILE_ERRORS:-0}
  unfinished=${TESTS_UNFINISHED:-0}
  if [ $((failed + broken + unfinished)) -gt 0 ]; then
    echo "::error::$failed test(s) failed, $broken test file error(s), $unfinished test(s) did not finish — see the job summary and PR comment."
  else
    echo "::error::flutter test failed without a failing test (a timeout, a crash or an error outside any test) — see the test step's log."
  fi
  ok=0
fi

if [ -z "$total" ] || [ "$total" -eq 0 ]; then
  echo "::error::Coverage was not measured: coverage/lcov.info was missing or empty."
  ok=0
else
  # The small epsilon keeps float error from turning an exact 242.0 into 243.
  needed=$(awk -v m="$MIN_COVERAGE" -v t="$total" \
    'BEGIN { n = m * t / 100 - 1e-9; c = int(n); if (c < n) c++; print c }')
  if [ "$covered" -lt "$needed" ]; then
    echo "::error::Coverage is below the ${MIN_COVERAGE}% gate: $covered of $total lines covered, $needed needed."
    ok=0
  fi
fi

if [ "$ok" -ne 1 ]; then
  exit 1
fi
echo "All tests passed; coverage $covered of $total lines meets the ${MIN_COVERAGE}% gate ($needed needed)."
