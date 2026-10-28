#!/usr/bin/env bash
# Builds the test reports and writes the extended one to the run Summary page.
#
# Used by UnitAndWidgetTesting.yml. test_summary.py turns the JSON test results
# into report.md (concise, for the PR comment) and summary.md (everything, for
# the run Summary page). The job's name already heads that page, so summary.md
# goes in as-is.
#
# Reads:  MIN_COVERAGE, TESTS_OUTCOME, COMMIT_SHA, REPO_URL, RUN_URL, and
#         COVERAGE_COVERED and COVERAGE_TOTAL when test_coverage.sh set them
# Writes: report.md, summary.md
# Sets for later steps:
#   TESTS_FAILED       failed tests
#   TESTS_FILE_ERRORS  test files that failed to load, set up or clean up
#   TESTS_UNFINISHED   tests that started but never finished
set -euo pipefail

counts=$(python3 "$(dirname "$0")/test_summary.py" test-results.json \
  --out report.md \
  --summary-out summary.md \
  --covered "${COVERAGE_COVERED:-}" \
  --total "${COVERAGE_TOTAL:-}" \
  --min-coverage "$MIN_COVERAGE" \
  --tests-outcome "${TESTS_OUTCOME:-}" \
  --commit "${COMMIT_SHA:-}" \
  --repo-url "${REPO_URL:-}" \
  --run-url "${RUN_URL:-}")
echo "$counts"

count() { printf '%s\n' "$counts" | sed -n "s/^$1=//p"; }
{
  echo "TESTS_FAILED=$(count failed)"
  echo "TESTS_FILE_ERRORS=$(count file_errors)"
  echo "TESTS_UNFINISHED=$(count unfinished)"
} >> "$GITHUB_ENV"

cat summary.md >> "$GITHUB_STEP_SUMMARY"
