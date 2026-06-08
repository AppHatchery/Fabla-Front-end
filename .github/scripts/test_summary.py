#!/usr/bin/env python3
"""Turn `flutter test --file-reporter json:` output into a Markdown report.

The Dart/Flutter JSON reporter emits one JSON object per line (a stream of
events). We fold those into pass/fail/skip counts and a list of failing tests
with their file and first error line, then write a Markdown report used for both
the GitHub Actions step summary and the sticky PR comment.

Usage:
    test_summary.py <results.json> <out.md> [coverage] [threshold]

Counts are also printed to stdout as `key=value` lines so the workflow can
capture them via $GITHUB_OUTPUT.
"""
import json
import sys


def load_events(path):
    try:
        with open(path, encoding="utf-8") as handle:
            for line in handle:
                line = line.strip()
                if not line:
                    continue
                try:
                    yield json.loads(line)
                except json.JSONDecodeError:
                    continue
    except FileNotFoundError:
        return


def main():
    results_path = sys.argv[1]
    out_path = sys.argv[2]
    coverage = sys.argv[3] if len(sys.argv) > 3 else ""
    threshold = sys.argv[4] if len(sys.argv) > 4 else ""

    names = {}        # testID -> test name
    test_suite = {}   # testID -> suiteID
    suite_path = {}   # suiteID -> file path
    errors = {}       # testID -> [error message, ...]
    results = {}      # testID -> {result, skipped, hidden}

    for event in load_events(results_path):
        kind = event.get("type")
        if kind == "suite":
            suite = event["suite"]
            path = suite.get("path") or ""
            # Trim the runner's absolute prefix to a repo-relative test/ path.
            if "/test/" in path:
                path = path[path.index("/test/") + 1:]
            suite_path[suite["id"]] = path
        elif kind == "testStart":
            test = event["test"]
            names[test["id"]] = test.get("name", "")
            test_suite[test["id"]] = test.get("suiteID")
        elif kind == "error":
            errors.setdefault(event["testID"], []).append(event.get("error", ""))
        elif kind == "testDone":
            results[event["testID"]] = {
                "result": event.get("result"),
                "skipped": event.get("skipped", False),
                "hidden": event.get("hidden", False),
            }

    passed = failed = skipped = 0
    failures = []  # (name, path, first_error_line)
    for tid, res in results.items():
        if res["hidden"]:  # loading/tearDown bookkeeping entries
            continue
        if res["skipped"]:
            skipped += 1
        elif res["result"] == "success":
            passed += 1
        else:
            failed += 1
            err = (errors.get(tid, [""]) or [""])[0].strip().splitlines()
            failures.append((
                names.get(tid, f"test #{tid}"),
                suite_path.get(test_suite.get(tid), ""),
                err[0] if err else (res["result"] or "failed"),
            ))

    total = passed + failed + skipped
    icon = "✅" if failed == 0 and total > 0 else ("❌" if failed else "⚠️")

    lines = [
        f"## {icon} Unit & Widget Tests",
        "",
        "| Result | Count |",
        "| --- | ---: |",
        f"| ✅ Passed | {passed} |",
        f"| ❌ Failed | {failed} |",
        f"| ⏭️ Skipped | {skipped} |",
        f"| **Total** | **{total}** |",
        "",
    ]

    if coverage:
        gate = f" · gate {threshold}%" if threshold else ""
        cov_icon = ""
        if threshold:
            try:
                cov_icon = " ✅" if float(coverage) >= float(threshold) else " ❌"
            except ValueError:
                cov_icon = ""
        lines.append(f"**Test Coverage: {coverage}%{gate}**{cov_icon}")
        lines.append("")

    if failures:
        lines.append("### Failing tests")
        lines.append("")
        for name, path, first in failures[:50]:
            location = f" — `{path}`" if path else ""
            lines.append(f"- **{name}**{location}")
            if first:
                lines.append(f"  > {first[:300]}")
        if len(failures) > 50:
            lines.append(f"- …and {len(failures) - 50} more")
        lines.append("")

    if total == 0:
        lines.append("> ⚠️ No test results were parsed — the run likely failed "
                     "before tests executed (build/setup error). Check the log.")
        lines.append("")

    with open(out_path, "w", encoding="utf-8") as out:
        out.write("\n".join(lines) + "\n")

    print(f"passed={passed}")
    print(f"failed={failed}")
    print(f"skipped={skipped}")
    print(f"total={total}")


if __name__ == "__main__":
    main()
