#!/usr/bin/env bash
# The one place the job fails: tests must pass and coverage must meet the gate.
#
# Used by UnitAndWidgetTesting.yml. Each reason is its own ::error:: annotation,
# so when both fail, both show.
#
# Reads: TESTS_OUTCOME (the test step's outcome), MIN_COVERAGE, and COVERAGE
#        and TESTS_FAILED when earlier steps set them
set -euo pipefail

# No coverage number means coverage was not measured, which must not pass.
coverage=${COVERAGE:-0}

ok=1
if [ "$TESTS_OUTCOME" != success ]; then
  echo "::error::${TESTS_FAILED:-Some} test(s) failed — see the job summary and PR comment."
  ok=0
fi
if ! awk "BEGIN {exit !($coverage >= $MIN_COVERAGE)}"; then
  echo "::error::Coverage $coverage% is below the gate of ${MIN_COVERAGE}%."
  ok=0
fi
if [ "$ok" -ne 1 ]; then
  exit 1
fi
echo "All tests passed; coverage $coverage% >= ${MIN_COVERAGE}%."
