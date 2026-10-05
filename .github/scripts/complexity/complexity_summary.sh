#!/usr/bin/env bash
# Writes the audit report to the run Summary page, saying what was compared.
#
# Used by Complexity_Checker.yml. Runs even when the audit failed, so a missing
# report still leaves a heading and a note rather than an empty page.
#
# Reads: RELEASE_TAG, and PREVIOUS_TAG when complexity_previous_release.sh set it
set -euo pipefail

if [ -n "${PREVIOUS_TAG:-}" ]; then
  compared="Release \`$RELEASE_TAG\` compared with the previous release \`$PREVIOUS_TAG\`."
else
  compared="Release \`$RELEASE_TAG\`. No earlier release was found, so every unit over the threshold is listed."
fi

{
  if [ -f complexity-summary.md ]; then
    # The report's heading stays first; what was compared goes under it.
    head -n 1 complexity-summary.md
    echo
    echo "$compared"
    tail -n +2 complexity-summary.md
  else
    echo "## Complexity Score and Suggestions"
    echo
    echo "$compared"
    echo
    echo "_Complexity report was not generated._"
  fi
} >> "$GITHUB_STEP_SUMMARY"
