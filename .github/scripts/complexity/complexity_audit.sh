#!/usr/bin/env bash
# Audits this release against the previous one, without blocking anything.
#
# Used by Complexity_Checker.yml. The release is already published, so there is
# nothing to block: anything new or worse than the previous release raises a
# warning. Only a usage error (2) or an internal error such as a parse failure
# (3) fails the step.
#
# Reads:  RELEASE_TAG, AUDIT_THRESHOLD, AUDIT_EXCLUDE, and PREVIOUS_TAG and
#         PREVIOUS_BASELINE when complexity_previous_release.sh set them
# Writes: complexity-report.md, complexity-summary.md, audit.log
# Sets for later steps:
#   AUDIT_CODE    the tool's exit code
#   AUDIT_RESULT  its final `RESULT:` line
set -euo pipefail

args=(
  --threshold "$AUDIT_THRESHOLD"
  --exclude "$AUDIT_EXCLUDE"
  --output-path complexity-report.md
  --summary-out complexity-summary.md
  --fail-on-threshold
)
if [ -n "${PREVIOUS_BASELINE:-}" ]; then
  args+=(--baseline "$PREVIOUS_BASELINE")
fi

code=0
dart run tool/complexity_audit.dart "${args[@]}" > audit.log 2>&1 || code=$?
cat audit.log

echo "AUDIT_CODE=$code" >> "$GITHUB_ENV"
echo "AUDIT_RESULT=$(grep '^RESULT:' audit.log | tail -n 1 || true)" >> "$GITHUB_ENV"

case "$code" in
  0) ;;
  1)
    if [ -n "${PREVIOUS_TAG:-}" ]; then
      echo "::warning::$RELEASE_TAG has units new or worse than $PREVIOUS_TAG over complexity $AUDIT_THRESHOLD — see the job summary."
    else
      echo "::warning::$RELEASE_TAG has units over complexity $AUDIT_THRESHOLD — see the job summary."
    fi
    ;;
  *) exit "$code" ;;
esac
