#!/usr/bin/env bash
# Builds the test reports and writes the extended one to the run Summary page.
#
# Used by UnitAndWidgetTesting.yml. test_summary.py turns the JSON test results
# into report.md (concise, for the PR comment) and summary.md (extended: run
# details, slowest tests and a per-file breakdown).
#
# Reads:  MIN_COVERAGE, and COVERAGE and COVERAGE_LINES when test_coverage.sh
#         set them
# Writes: report.md, summary.md
# Sets for later steps:
#   TESTS_FAILED  the number of failed tests
set -euo pipefail

counts=$(python3 "$(dirname "$0")/test_summary.py" \
  test-results.json report.md \
  "${COVERAGE:-}" "$MIN_COVERAGE" \
  --summary-out summary.md \
  --lines "${COVERAGE_LINES:-}")
echo "$counts"
echo "TESTS_FAILED=$(printf '%s\n' "$counts" | sed -n 's/^failed=//p')" >> "$GITHUB_ENV"

{
  echo "## Test Results"
  cat summary.md
} >> "$GITHUB_STEP_SUMMARY"
