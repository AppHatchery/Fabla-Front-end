#!/usr/bin/env bash
# Counts covered lines for the code the coverage gate applies to.
#
# Used by UnitAndWidgetTesting.yml after `flutter test --coverage`. Generated
# code and files that are not unit-testable are removed from lcov.info first,
# so they neither raise nor lower the number.
#
# The counts are summed from the per-file LH/LF records rather than read from
# `lcov --summary`, which rounds to one decimal: 23.955% would print as 24.0%
# and pass a 24% gate.
#
# Reads:   MIN_COVERAGE (for the log line only)
# Changes: coverage/lcov.info, filtered in place
# Sets for later steps (both empty when there is no lcov.info):
#   COVERAGE_COVERED  covered lines
#   COVERAGE_TOTAL    instrumented lines
set -euo pipefail

covered=""
total=""
if [ -f coverage/lcov.info ]; then
  sudo apt-get install -y lcov
  lcov --remove coverage/lcov.info \
    'lib/**/*.g.dart' \
    'lib/**/*.freezed.dart' \
    'lib/objectbox.g.dart' \
    'lib/main.dart' \
    'lib/firebase_options.dart' \
    'lib/theme/**' \
    'lib/core/utils/dummy_data.dart' \
    'lib/core/utils/errorCodes.dart' \
    'lib/core/utils/emailFunction.dart' \
    -o coverage/lcov.info --ignore-errors unused
  read -r covered total < <(
    awk -F: '$1 == "LH" { c += $2 } $1 == "LF" { t += $2 } END { print c + 0, t + 0 }' \
      coverage/lcov.info)
  echo "Coverage: $covered of $total lines (gate ${MIN_COVERAGE}%)"
else
  echo "::warning::coverage/lcov.info is missing, so coverage was not measured."
fi

echo "COVERAGE_COVERED=$covered" >> "$GITHUB_ENV"
echo "COVERAGE_TOTAL=$total" >> "$GITHUB_ENV"
