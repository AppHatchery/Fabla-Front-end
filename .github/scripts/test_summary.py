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
    failures = []
    for tid, res in results.items():
        if res["hidden"]:
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
    pass_rate = (passed / total * 100) if total else 0.0
    icon = "✅" if failed == 0 and total > 0 else ("❌" if failed else "⚠️")
    status_word = "PASSED" if failed == 0 and total > 0 else ("FAILED" if failed else "NO TESTS")

    def bar(pct, width=20):
        filled = round(width * pct / 100)
        return "█" * filled + "░" * (width - filled)

    lines = [
        f"## {icon} Unit & Widget Tests — {status_word}",
        "",
        f"`{bar(pass_rate)}` **{pass_rate:.1f}%** pass rate ({passed}/{total})",
        "",
        "| ✅ Passed | ❌ Failed | ⏭️ Skipped | Σ Total |",
        "| :---: | :---: | :---: | :---: |",
        f"| {passed} | {failed} | {skipped} | **{total}** |",
        "",
    ]

    if coverage:
        try:
            cov_val = float(coverage)
            gate_val = float(threshold) if threshold else None
        except ValueError:
            cov_val, gate_val = None, None

        if cov_val is not None:
            cov_icon = "✅" if gate_val is not None and cov_val >= gate_val else (
                "❌" if gate_val is not None else "📊"
            )
            gate = f" (gate: {threshold}%)" if threshold else ""
            lines.append(f"`{bar(cov_val)}` {cov_icon} **Coverage: {coverage}%**{gate}")
        else:
            lines.append(f"📊 **Coverage: {coverage}%**")
        lines.append("")

    if failures:
        lines.append(f"### ❌ {len(failures)} Failing Test{'s' if len(failures) != 1 else ''}")
        lines.append("")
        # Collapsed by default when the list is long, so the PR comment stays scannable.
        collapse = len(failures) > 10
        if collapse:
            lines.append("<details>")
            lines.append(f"<summary>Show {len(failures)} failures</summary>")
            lines.append("")
        for name, path, first in failures[:50]:
            location = f" · `{path}`" if path else ""
            lines.append(f"**`{name}`**{location}")
            if first:
                lines.append("```")
                lines.append(first[:300])
                lines.append("```")
        if len(failures) > 50:
            lines.append(f"_…and {len(failures) - 50} more_")
        if collapse:
            lines.append("")
            lines.append("</details>")
        lines.append("")

    if total == 0:
        lines.append("> ⚠️ **No test results were parsed** — the run likely failed "
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