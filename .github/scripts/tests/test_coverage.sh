#!/usr/bin/env bash
# Computes line coverage for the code the coverage gate applies to.
#
# Used by UnitAndWidgetTesting.yml after `flutter test --coverage`. Generated
# code and files that are not unit-testable are removed from lcov.info first,
# so they neither raise nor lower the number.
#
# Reads:   MIN_COVERAGE (for the log line only)
# Changes: coverage/lcov.info, filtered in place
# Sets for later steps:
#   COVERAGE        line coverage percent, 0 when there is no lcov.info
#   COVERAGE_LINES  "<covered> of <total>", empty when unknown
set -euo pipefail

sudo apt-get install -y lcov

coverage="0"
lines=""
if [ -f coverage/lcov.info ]; then
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
  summary=$(lcov --summary coverage/lcov.info 2>&1)
  coverage=$(echo "$summary" | grep -oP 'lines.*: \K[0-9.]+(?=%)' || echo "0")
  lines=$(echo "$summary" | grep -oP 'lines.*\(\K[0-9]+ of [0-9]+(?= lines\))' || echo "")
fi

echo "COVERAGE=$coverage" >> "$GITHUB_ENV"
echo "COVERAGE_LINES=$lines" >> "$GITHUB_ENV"
echo "Coverage: $coverage% (gate ${MIN_COVERAGE}%)"
