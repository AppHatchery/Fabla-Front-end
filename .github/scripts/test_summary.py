#!/usr/bin/env python3
"""Turn `flutter test --file-reporter json:` output into Markdown reports.

The Dart/Flutter JSON reporter emits one JSON object per line (a stream of
events). We fold those into pass/fail/skip counts, per-file results, timings,
and a list of failing tests, then write:

  * <out.md>            concise report used for the sticky PR comment
  * --summary-out FILE  extended report for the Actions run Summary page
                        (adds run details, slowest tests, per-file breakdown)

Usage:
    test_summary.py <results.json> <out.md> [coverage] [threshold]
        [--summary-out summary.md] [--lines "<covered> of <total>"]

Counts are also printed to stdout as `key=value` lines so the workflow can
capture them via $GITHUB_OUTPUT.
"""
import argparse
import heapq
import json


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


def fmt_ms(ms):
    if ms >= 60_000:
        return f"{int(ms // 60_000)}m {round((ms % 60_000) / 1000)}s"
    if ms >= 1_000:
        return f"{ms / 1000:.1f}s"
    return f"{int(ms)}ms"


def md_escape(text, limit=90):
    text = text.replace("|", "\\|")
    return text[: limit - 1] + "…" if len(text) > limit else text


def bar(pct, width=20):
    filled = round(width * pct / 100)
    return "█" * filled + "░" * (width - filled)


def parse_results(results_path):
    names = {}
    test_suite = {}
    suite_path = {}
    errors = {}
    results = {}
    starts = {}
    durations = {}
    run_ms = 0

    for event in load_events(results_path):
        run_ms = max(run_ms, event.get("time", 0))
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
            starts[test["id"]] = event.get("time", 0)
        elif kind == "error":
            errors.setdefault(event["testID"], []).append(event.get("error", ""))
        elif kind == "testDone":
            tid = event["testID"]
            results[tid] = {
                "result": event.get("result"),
                "skipped": event.get("skipped", False),
                "hidden": event.get("hidden", False),
            }
            if tid in starts:
                durations[tid] = max(0, event.get("time", 0) - starts[tid])

    passed = failed = skipped = 0
    failures = []
    per_file = {}     # path -> [passed, failed, skipped]
    for tid, res in results.items():
        if res["hidden"]:
            continue
        path = suite_path.get(test_suite.get(tid), "")
        counts = per_file.setdefault(path, [0, 0, 0])
        if res["skipped"]:
            skipped += 1
            counts[2] += 1
        elif res["result"] == "success":
            passed += 1
            counts[0] += 1
        else:
            failed += 1
            counts[1] += 1
            err = (errors.get(tid, [""]) or [""])[0].strip().splitlines()
            failures.append((
                names.get(tid, f"test #{tid}"),
                path,
                err[0] if err else (res["result"] or "failed"),
            ))

    total = passed + failed + skipped
    return {
        "passed": passed,
        "failed": failed,
        "skipped": skipped,
        "total": total,
        "failures": failures,
        "per_file": per_file,
        "run_ms": run_ms,
        "durations": durations,
        "names": names,
        "suite_path": suite_path,
        "test_suite": test_suite,
        "results": results
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("results")
    parser.add_argument("out")
    parser.add_argument("coverage", nargs="?", default="")
    parser.add_argument("threshold", nargs="?", default="")
    parser.add_argument("--summary-out", default="")
    parser.add_argument("--lines", default="",
                        help='lcov line detail, e.g. "1234 of 3032"')
    parser.add_argument("--val-results", default="",
                        help="JSON reporter output for validator tests")
    parser.add_argument("--val-coverage", default="",
                        help="Validator coverage percentage")
    parser.add_argument("--val-lines", default="",
                        help="Validator lcov line detail")
    parser.add_argument("--val-threshold", default="",
                        help="Validator coverage gate percentage")
    parser.add_argument("--val-report", default="",
                        help="Path to the validator's markdown report")
    args = parser.parse_args()

    app_res = parse_results(args.results)
    passed = app_res["passed"]
    failed = app_res["failed"]
    skipped = app_res["skipped"]
    total = app_res["total"]
    failures = app_res["failures"]
    per_file = app_res["per_file"]
    run_ms = app_res["run_ms"]
    durations = app_res["durations"]
    names = app_res["names"]
    suite_path = app_res["suite_path"]
    test_suite = app_res["test_suite"]
    results = app_res["results"]

    pass_rate = (passed / total * 100) if total else 0.0
    icon = "✅" if failed == 0 and total > 0 else ("❌" if failed else "⚠️")
    status_word = "PASSED" if failed == 0 and total > 0 else ("FAILED" if failed else "NO TESTS")

    lines = [
        f"## Unit & Widget Tests — {status_word} {icon}",
        "",
        f"`{bar(pass_rate)}` **{pass_rate:.1f}%** pass rate ({passed}/{total})",
        "",
        "| Passed | Failed | Skipped | Total |",
        "| :---: | :---: | :---: | :---: |",
        f"| {passed} | {failed} | {skipped} | **{total}** |",
        "",
    ]

    # Coverage gate block, styled as a Metric/Value table so the PR comment
    # reads the same as the run summary: explicit PASS/FAIL + the numbers.
    try:
        cov_val = float(args.coverage) if args.coverage else None
        gate_val = float(args.threshold) if args.threshold else None
    except ValueError:
        cov_val, gate_val = None, None

    if cov_val is not None and gate_val is not None:
        gate_status = "✅ PASS" if cov_val >= gate_val else "❌ FAIL"
        detail = f" ({args.lines.replace(' of ', '/')} lines)" if args.lines else ""
        lines += [
            f"### Coverage gate {gate_status}",
            "",
            "| Metric | Value |",
            "| --- | --- |",
            f"| Line coverage | **{cov_val:.2f}%**{detail} |",
            f"| Threshold | {gate_val:.2f}% |",
            "",
        ]
    elif cov_val is not None:
        lines += [f"📊 **Coverage: {cov_val:.2f}%**", ""]

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

    #  Release Validator Integration
    if args.val_report:
        try:
            with open(args.val_report, "r", encoding="utf-8") as f:
                lines += [f.read().rstrip("\n"), ""]
        except FileNotFoundError:
            lines += [
                "### 🧱 ObjectBox Schema Validation",
                "",
                "> ⚠️ No validator report was produced — the schema validation "
                "step did not complete. Check the *Run ObjectBox schema "
                "validation* step in the run log.",
                "",
            ]

    # Validator Tests is independent of the schema report: the tool's own
    # tests can pass while the schema check fails, and vice versa.
    if args.val_results or args.val_coverage:
        lines += ["#### Validator Tests", ""]

        if args.val_results:
            v_res = parse_results(args.val_results)
            v_total = v_res["total"]
            v_passed = v_res["passed"]
            v_failed = v_res["failed"]
            v_skipped = v_res["skipped"]
            v_pass_rate = (v_passed / v_total * 100) if v_total else 0.0

            lines += [
                "| Passed | Failed | Skipped | Total | Pass Rate |",
                "| :---: | :---: | :---: | :---: | :---: |",
                f"| {v_passed} | {v_failed} | {v_skipped} | {v_total} "
                f"| {v_pass_rate:.1f}% |",
                "",
            ]
            if v_total == 0:
                lines += [
                    "> ⚠️ No validator test results were parsed — the tool's "
                    "tests did not run.",
                    "",
                ]

        if args.val_coverage:
            v_detail = (f" ({args.val_lines.replace(' of ', '/')} lines)"
                        if args.val_lines else "")
            try:
                v_cov = float(args.val_coverage)
                v_gate = float(args.val_threshold) if args.val_threshold else None
            except ValueError:
                v_cov, v_gate = None, None

            if v_cov is not None and v_gate is not None:
                v_status = "✅ PASS" if v_cov >= v_gate else "❌ FAIL"
                lines += [
                    f"**Validator coverage gate {v_status}** — "
                    f"**{v_cov:.2f}%**{v_detail}, threshold {v_gate:.2f}%",
                    "",
                ]
            else:
                lines += [
                    f"**Validator line coverage:** {args.val_coverage}%{v_detail}",
                    "",
                ]

    with open(args.out, "w", encoding="utf-8") as out:
        out.write("\n".join(lines) + "\n")

    # Extended report for the Actions run Summary page: everything above plus
    # run details, the slowest tests, and a collapsed per-file breakdown.
    if args.summary_out:
        extra = list(lines)
        if total > 0:
            extra += [
                "### Run details",
                "",
                "| Metric | Value |",
                "| --- | --- |",
                f"| Wall-clock test time | {fmt_ms(run_ms)} |",
                f"| Test files | {len(per_file)} |",
                f"| Tests executed | {total} |",
                "",
            ]

            # Only real, executed tests — no hidden loader entries, no skips.
            ran = {
                tid: ms for tid, ms in durations.items()
                if ms > 0 and tid in results
                and not results[tid]["hidden"] and not results[tid]["skipped"]
            }
            slowest = heapq.nlargest(10, ran.items(), key=lambda kv: kv[1])
            if slowest:
                extra += [
                    "### 🐢 Slowest tests",
                    "",
                    "| Test | File | Duration |",
                    "| --- | --- | ---: |",
                ]
                for tid, ms in slowest:
                    extra.append(
                        f"| {md_escape(names.get(tid, f'test #{tid}'))} "
                        f"| `{suite_path.get(test_suite.get(tid), '')}` "
                        f"| {fmt_ms(ms)} |"
                    )
                extra.append("")

            extra += [
                "<details>",
                f"<summary>Per-file results ({len(per_file)} files)</summary>",
                "",
                "| File | Passed | Failed | Skipped |",
                "| --- | ---: | ---: | ---: |",
            ]
            # Failing files first, then alphabetical, so problems surface on top.
            for path, (p, f, s) in sorted(per_file.items(),
                                          key=lambda kv: (-kv[1][1], kv[0])):
                extra.append(f"| `{path}` | {p} | {'**' + str(f) + '**' if f else 0} | {s} |")
            extra += ["", "</details>", ""]

        with open(args.summary_out, "w", encoding="utf-8") as out:
            out.write("\n".join(extra) + "\n")

    print(f"passed={passed}")
    print(f"failed={failed}")
    print(f"skipped={skipped}")
    print(f"total={total}")


if __name__ == "__main__":
    main()
