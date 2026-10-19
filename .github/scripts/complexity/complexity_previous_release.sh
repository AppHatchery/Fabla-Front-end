#!/usr/bin/env bash
# Measures the previous v-tagged release so the audit can compare against it.
#
# Used by Complexity_Checker.yml. The previous release is measured by this
# release's tool, so both sides are counted the same way. Describing from HEAD^
# means a release is never compared with itself, and only tags this one
# descends from count, so a patch tag on another branch is skipped.
#
# Reads:  AUDIT_THRESHOLD, AUDIT_EXCLUDE, RUNNER_TEMP
# Sets for later steps (left unset when there is no earlier release):
#   PREVIOUS_TAG       the previous release's tag
#   PREVIOUS_BASELINE  the baseline written from it
set -euo pipefail

prev=$(git describe --tags --abbrev=0 --match 'v*' --match 'V*' HEAD^ 2>/dev/null || true)
if [ -z "$prev" ]; then
  echo "::notice::No earlier v-tagged release — reporting against the raw threshold."
  exit 0
fi

checkout="$RUNNER_TEMP/previous"
baseline="$RUNNER_TEMP/previous-baseline.json"

git worktree add --detach "$checkout" "$prev"
dart run tool/complexity_audit.dart \
  --root "$checkout" \
  --threshold "$AUDIT_THRESHOLD" \
  --exclude "$AUDIT_EXCLUDE" \
  --baseline "$baseline" \
  --update-baseline

echo "PREVIOUS_TAG=$prev" >> "$GITHUB_ENV"
echo "PREVIOUS_BASELINE=$baseline" >> "$GITHUB_ENV"
