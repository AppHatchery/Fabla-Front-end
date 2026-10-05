#!/usr/bin/env python3
"""Turn `flutter test --file-reporter json:` output into Markdown reports.

Two reports come out of one run:

  * --out FILE          concise report for the sticky PR comment
  * --summary-out FILE  the same, plus every failure in full, the slowest tests
                        and the files with problems, for the run Summary page

The verdict uses the same inputs as test_gate.sh, so a report can never say
"passed" on a job that fails. It counts failed tests (including errors raised
after a test completed), files that failed to load, set up or clean up, tests that never
finished, a run that stopped early, and the coverage gate.

Usage:
    test_summary.py <results.json> --out report.md [--summary-out summary.md]
        [--covered N --total N --min-coverage PCT] [--tests-outcome OUTCOME]
        [--commit SHA] [--repo-url URL] [--run-url URL]

Counts are printed to stdout as `key=value` lines for test_report.sh.
"""
from __future__ import annotations

import argparse
import heapq
import json
import math
import os
import re
from dataclasses import dataclass, field
from fractions import Fraction

# GitHub rejects a comment over 65,536 characters; the step summary allows
# 1 MiB. Both budgets are measured in UTF-8 bytes, which is never less.
COMMENT_LIMIT = 60_000
SUMMARY_LIMIT = 900_000

# Failures shown open in the PR comment; the rest are behind one click.
COMMENT_OPEN_FAILURES = 5

ERROR_MAX_LINES = 20
ERROR_MAX_CHARS = 2_000

# A matcher failure reads Expected / Actual / Which. Each part is capped on its
# own, so a long expected list can never push "Actual:" out of the report.
_MATCHER_PART = re.compile(r"^\s*(Expected|Actual|Which):")
MATCHER_PART_MAX_LINES = 5

# A test file and line in a stack frame, a widget-test exception or a compiler
# error: `test/x_test.dart 9:5`, `test/x_test.dart:9:5`, `test/x_test.dart line 9`.
# The look-behind keeps `flutter_test/src/...` from matching.
_TEST_FILE_LINE = re.compile(r"(?<![\w.-])(test/[\w./-]+?\.dart)(?: line |:| )(\d+)")


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


def plural(count, word, many=None):
    return f"{count} {word if count == 1 else (many or word + 's')}"


# --------------------------------------------------------------------- parse


@dataclass
class TestRecord:
    """Everything the reporter said about one test ID."""

    id: int
    name: str = ""
    suite_id: int | None = None
    declared_line: int | None = None
    skip_reason: str | None = None
    start_ms: int | None = None
    done_ms: int | None = None
    result: str | None = None
    skipped: bool = False
    hidden: bool = False
    # "test", or for entries that stand for a whole file: "load", "setUpAll",
    # "tearDownAll".
    kind: str = "test"
    errors: list[str] = field(default_factory=list)
    stacks: list[str] = field(default_factory=list)
    prints: list[str] = field(default_factory=list)
    late_error: bool = False
    path: str = ""
    location: tuple[str, int | None] | None = None
    detail: str = ""

    @property
    def finished(self):
        return self.done_ms is not None

    @property
    def failed(self):
        # An error after `testDone: success` still fails the run.
        return self.finished and not self.skipped and (
            self.result != "success" or bool(self.errors))

    @property
    def duration_ms(self):
        if self.start_ms is None or self.done_ms is None:
            return None
        return max(0, self.done_ms - self.start_ms)


@dataclass
class RunResult:
    tests: list[TestRecord]
    file_errors: list[TestRecord]
    completed: bool
    success: bool | None
    run_ms: int

    @property
    def passed(self):
        return [t for t in self.tests if t.finished and not t.skipped and not t.failed]

    @property
    def failed(self):
        return [t for t in self.tests if t.failed]

    @property
    def skipped(self):
        return [t for t in self.tests if t.finished and t.skipped]

    @property
    def unfinished(self):
        return [t for t in self.tests if not t.finished]

    @property
    def total(self):
        return len(self.passed) + len(self.failed) + len(self.skipped)


def strip_workspace(text, workspace):
    """Turns absolute runner paths into repo-relative ones."""
    if not workspace:
        return text
    root = workspace.rstrip("/") + "/"
    return text.replace("file://" + root, "").replace(root, "")


def _relative_path(path, workspace):
    path = strip_workspace(path, workspace)
    if path.startswith("/") and "/test/" in path:
        path = path[path.index("/test/") + 1:]
    return path


def _kind_of(name, suite_abs_path):
    if suite_abs_path and name == f"loading {suite_abs_path}":
        return "load"
    for hook in ("setUpAll", "tearDownAll"):
        if name == f"({hook})" or name.endswith(f" ({hook})"):
            return hook
    return "test"


def _widget_exception(prints):
    """The assertion text a failed testWidgets prints, minus banner and stack."""
    for message in prints:
        lines = message.splitlines()
        start = next((i for i, line in enumerate(lines)
                      if line.startswith("The following ")), None)
        if start is None:
            continue
        end = next((i for i in range(start + 1, len(lines))
                    if lines[i].startswith(("When the exception was thrown",
                                            "The test description was",
                                            "═"))), len(lines))
        return "\n".join(lines[start:end]).strip()
    return None


def _cap_matcher_parts(lines):
    parts = [[]]
    for line in lines:
        if _MATCHER_PART.match(line) and parts[-1]:
            parts.append([])
        parts[-1].append(line)
    if len(parts) == 1:
        return lines
    capped = []
    for part in parts:
        capped += part[:MATCHER_PART_MAX_LINES]
        if len(part) > MATCHER_PART_MAX_LINES:
            capped.append("  …")
    return capped


def _cap(text):
    lines = _cap_matcher_parts(text.splitlines())
    joined = "\n".join(lines)
    cut = len(lines) > ERROR_MAX_LINES or len(joined) > ERROR_MAX_CHARS
    text = "\n".join(lines[:ERROR_MAX_LINES])[:ERROR_MAX_CHARS].rstrip()
    return text + "\n…" if cut else text


def _detail_of(record, workspace):
    parts = []
    for error in record.errors:
        if error.startswith("Test failed. See exception logs above."):
            error = _widget_exception(record.prints) or error
        if error.strip():
            parts.append(error.strip())
    if not parts:
        parts.append(record.result or "failed")
    return _cap(strip_workspace("\n\n".join(parts), workspace))


def _location_of(record, workspace):
    """Where it failed: the assertion's frame, else where the test is declared."""
    exception_prints = [p for p in record.prints if "EXCEPTION CAUGHT" in p]
    for text in record.stacks + exception_prints + record.errors:
        match = _TEST_FILE_LINE.search(strip_workspace(text, workspace))
        if match:
            return match.group(1), int(match.group(2))
    if record.path:
        return record.path, record.declared_line
    return None


def parse_events(events, workspace=""):
    """Folds reporter events into a RunResult. O(events)."""
    records = {}
    suite_abs = {}
    suite_rel = {}
    completed = False
    success = None
    run_ms = 0

    for event in events:
        run_ms = max(run_ms, event.get("time", 0))
        kind = event.get("type")
        if kind == "suite":
            suite = event["suite"]
            suite_abs[suite["id"]] = suite.get("path") or ""
            suite_rel[suite["id"]] = _relative_path(suite.get("path") or "", workspace)
        elif kind == "testStart":
            test = event["test"]
            record = records.setdefault(test["id"], TestRecord(test["id"]))
            record.name = strip_workspace(test.get("name", ""), workspace)
            record.suite_id = test.get("suiteID")
            record.kind = _kind_of(test.get("name", ""), suite_abs.get(record.suite_id))
            record.skip_reason = (test.get("metadata") or {}).get("skipReason")
            record.start_ms = event.get("time", 0)
            # testWidgets reports flutter_test's own file as `url`; the test's
            # line in the caller's file is `root_line`.
            if test.get("root_url"):
                record.declared_line = test.get("root_line")
            elif "/test/" in (test.get("url") or ""):
                record.declared_line = test.get("line")
        elif kind == "error":
            record = records.setdefault(event["testID"], TestRecord(event["testID"]))
            record.errors.append(event.get("error", ""))
            record.stacks.append(event.get("stackTrace", ""))
            if record.finished:
                record.late_error = True
        elif kind == "print":
            record = records.setdefault(event["testID"], TestRecord(event["testID"]))
            record.prints.append(event.get("message", ""))
        elif kind == "testDone":
            record = records.setdefault(event["testID"], TestRecord(event["testID"]))
            record.done_ms = event.get("time", 0)
            record.result = event.get("result")
            record.skipped = event.get("skipped", False)
            record.hidden = event.get("hidden", False)
        elif kind == "done":
            completed = True
            success = event.get("success")

    tests, file_errors = [], []
    for record in records.values():
        record.path = suite_rel.get(record.suite_id, "")
        if record.kind != "test":
            if record.failed:
                record.detail = _detail_of(record, workspace)
                file_errors.append(record)
            continue
        if record.hidden or record.start_ms is None:
            continue
        if record.failed:
            record.detail = _detail_of(record, workspace)
        record.location = _location_of(record, workspace)
        tests.append(record)

    def by_place(record):
        line = record.location[1] if record.location and record.location[1] else 0
        return record.path, line, record.name

    tests.sort(key=by_place)
    file_errors.sort(key=lambda r: (r.path, r.kind))
    return RunResult(tests, file_errors, completed, success, run_ms)


# ------------------------------------------------------------------ coverage


@dataclass
class Coverage:
    """Line coverage, compared exactly: no lcov rounding decides the gate."""

    covered: int | None = None
    total: int | None = None
    minimum: Fraction | None = None

    @property
    def requested(self):
        return self.minimum is not None or self.total is not None

    @property
    def measured(self):
        return self.covered is not None and bool(self.total)

    @property
    def required(self):
        return math.ceil(self.minimum * self.total / 100)

    @property
    def passes(self):
        if self.minimum is None:
            return True
        return self.measured and self.covered >= self.required

    def percent_text(self):
        # Rounded down, so 23.996% never shows as a passing 24.00%.
        hundredths = self.covered * 10_000 // self.total
        return f"{hundredths // 100}.{hundredths % 100:02d}%"

    def minimum_text(self):
        value = self.minimum
        return f"{value.numerator}%" if value.denominator == 1 else f"{float(value):g}%"


def coverage_line(coverage):
    if not coverage.requested:
        return None
    if not coverage.measured:
        gate = f", so the {coverage.minimum_text()} gate fails" if coverage.minimum is not None else ""
        return f"Coverage: **not measured** · `coverage/lcov.info` was missing or empty{gate}"
    line = (f"Coverage: **{coverage.percent_text()}** "
            f"({coverage.covered} of {coverage.total} lines)")
    if coverage.minimum is None:
        return line
    spare = coverage.covered - coverage.required
    gate = f"the {coverage.minimum_text()} gate"
    if spare > 0:
        return f"{line} · {plural(spare, 'line')} above {gate}"
    if spare == 0:
        return f"{line} · exactly at {gate}"
    return f"{line} · **{plural(-spare, 'more line')} needed** for {gate}"


# -------------------------------------------------------------------- render


@dataclass
class Context:
    commit: str = ""
    repo_url: str = ""
    run_url: str = ""
    tests_outcome: str = ""


def code_span(text):
    """Inline code that survives backticks inside the text."""
    text = " ".join(text.splitlines())
    longest = max((len(run) for run in re.findall(r"`+", text)), default=0)
    ticks = "`" * (longest + 1)
    pad = " " if text.startswith("`") or text.endswith("`") else ""
    return f"{ticks}{pad}{text}{pad}{ticks}"


def fenced(text):
    """A code block whose fence is longer than any backtick run inside it."""
    longest = max((len(run) for run in re.findall(r"`+", text)), default=0)
    fence = "`" * max(3, longest + 1)
    return [fence, text, fence]


def cell(text):
    return code_span(text).replace("|", "\\|")


def location_text(location, ctx):
    if not location:
        return ""
    path, line = location
    label = code_span(f"{path}:{line}" if line else path)
    if ctx.repo_url and ctx.commit:
        anchor = f"#L{line}" if line else ""
        return f"[{label}]({ctx.repo_url}/blob/{ctx.commit}/{path}{anchor})"
    return label


def problems(run, coverage, ctx):
    """Why the run fails, in plain words. Empty means it passed."""
    reasons = []
    if run.failed:
        reasons.append(f"{plural(len(run.failed), 'test')} failed")
    if run.file_errors:
        reasons.append(f"{plural(len(run.file_errors), 'test file')} had errors")
    if run.unfinished:
        reasons.append(f"{plural(len(run.unfinished), 'test')} did not finish")
    test_problem = bool(reasons)
    if run.total == 0 and not run.file_errors:
        reasons.append("no test results were found")
        test_problem = True
    elif not run.completed:
        reasons.append("the test run stopped before it finished")
        test_problem = True
    if not test_problem and (ctx.tests_outcome not in ("", "success")
                             or run.success is False):
        reasons.append("flutter test failed without a failing test")
    if coverage.requested and not coverage.passes:
        reasons.append("coverage is below the gate" if coverage.measured
                       else "coverage was not measured")
    return reasons


class _Budget:
    """Lines plus their running UTF-8 size, so a cap never means re-encoding."""

    def __init__(self, limit):
        self.limit = limit
        self.lines = []
        self.size = 0

    def add(self, *lines):
        for line in lines:
            self.lines.append(line)
            self.size += len(line.encode("utf-8")) + 1

    def fits(self, lines, reserve=600):
        needed = sum(len(line.encode("utf-8")) + 1 for line in lines)
        return self.size + needed + reserve <= self.limit


def _add_blocks(out, blocks):
    """Adds blocks in order until the budget runs out; returns how many were left."""
    for index, block in enumerate(blocks):
        if not out.fits(block):
            return len(blocks) - index
        out.add(*block)
    return 0


def _failure_block(record, ctx):
    where = location_text(record.location, ctx)
    late = " · failed after it had completed" if record.late_error else ""
    header = f"**{code_span(record.name)}**" + (f" · {where}" if where else "") + late
    return [header, *fenced(record.detail), ""]


def _file_error_block(record):
    what = {"load": "failed to load",
            "setUpAll": "`setUpAll` failed",
            "tearDownAll": "`tearDownAll` failed"}[record.kind]
    return [f"**{code_span(record.path or record.name)}** · {what}",
            *fenced(record.detail), ""]


def render(run, coverage, ctx, *, summary=False):
    """The PR comment, or with summary=True the Summary-page report."""
    out = _Budget(SUMMARY_LIMIT if summary else COMMENT_LIMIT)
    reasons = problems(run, coverage, ctx)
    omitted = 0

    out.add(f"### {'❌' if reasons else '✅'} Unit & Widget Tests "
            f"{'failed' if reasons else 'passed'}", "")
    counts = [f"{len(run.passed)} passed", f"{len(run.failed)} failed",
              f"{len(run.skipped)} skipped"]
    if run.unfinished:
        counts.append(f"{len(run.unfinished)} did not finish")
    if run.file_errors:
        counts.append(plural(len(run.file_errors), 'file error'))
    out.add(" · ".join(counts))
    cov = coverage_line(coverage)
    if cov:
        out.add("", cov)
    footer = []
    if ctx.commit:
        footer.append(f"Results for {code_span(ctx.commit[:7])}")
    if ctx.run_url:
        footer.append(f"[logs and full report]({ctx.run_url})")
    if footer:
        out.add("", f"<sub>{' · '.join(footer)}</sub>")
    out.add("")

    for reason, note in (
        ("no test results were found",
         "The run likely failed before any test ran (a build or setup error)."),
        ("the test run stopped before it finished",
         "It probably timed out or crashed. Tests still running are listed below."),
        ("flutter test failed without a failing test",
         "This usually means an error outside any test. The log has the details."),
    ):
        if reason in reasons:
            out.add(f"> **{reason[0].upper() + reason[1:]}.** {note}", "")

    if run.file_errors:
        out.add(f"#### {plural(len(run.file_errors), 'test file error')}", "")
        omitted += _add_blocks(out, [_file_error_block(r) for r in run.file_errors])

    if run.failed:
        out.add(f"#### {plural(len(run.failed), 'failing test')}", "")
        blocks = [_failure_block(r, ctx) for r in run.failed]
        open_count = len(blocks) if summary else COMMENT_OPEN_FAILURES
        omitted += _add_blocks(out, blocks[:open_count])
        rest = blocks[open_count:]
        if rest:
            out.add("<details>",
                    f"<summary>Show {plural(len(rest), 'more failing test')}</summary>", "")
            omitted += _add_blocks(out, rest)
            out.add("</details>", "")

    if run.unfinished:
        out.add(f"#### {plural(len(run.unfinished), 'test')} did not finish", "")
        lines = []
        for record in run.unfinished:
            # No duration: a killed run's JSON just stops, so the last event's
            # time says nothing about how long this test really ran.
            where = location_text(record.location, ctx)
            lines.append([f"- {code_span(record.name)}" + (f" · {where}" if where else "")
                          + " · still running when the run stopped"])
        omitted += _add_blocks(out, lines)
        out.add("")

    if run.skipped:
        out.add("<details>",
                f"<summary>{plural(len(run.skipped), 'skipped test')}</summary>", "")
        lines = []
        for record in run.skipped:
            where = location_text(record.location, ctx)
            reason = f" · {record.skip_reason}" if record.skip_reason else ""
            lines.append([f"- {code_span(record.name)}" + (f" · {where}" if where else "")
                          + reason])
        omitted += _add_blocks(out, lines)
        out.add("", "</details>", "")

    if summary and run.total:
        _add_slowest(out, run)
        _add_problem_files(out, run)

    if omitted:
        out.add(f"_{plural(omitted, 'more entry', 'more entries')} not shown to stay "
                f"within GitHub's size limit. The run log has them all._", "")
    return "\n".join(out.lines).rstrip() + "\n"


def _add_slowest(out, run):
    ran = [r for r in run.tests if r.finished and not r.skipped and r.duration_ms]
    slowest = heapq.nlargest(10, ran, key=lambda r: r.duration_ms)
    if not slowest:
        return
    lines = ["#### Slowest tests", "", "| Test | File | Duration |", "| --- | --- | ---: |"]
    for record in slowest:
        lines.append(f"| {cell(record.name)} | {cell(record.path)} | {fmt_ms(record.duration_ms)} |")
    # Optional context: dropped whole when the failures already used the room.
    if out.fits(lines):
        out.add(*lines, "")


def _add_problem_files(out, run):
    """Only files with something wrong; an all-green suite adds nothing here."""
    rows = {}
    for record in run.tests:
        counts = rows.setdefault(record.path, [0, 0, 0, 0])
        if record.failed:
            counts[0] += 1
        elif record.skipped:
            counts[1] += 1
        elif not record.finished:
            counts[2] += 1
    for record in run.file_errors:
        rows.setdefault(record.path, [0, 0, 0, 0])[3] += 1
    rows = {path: c for path, c in rows.items() if any(c)}
    if not rows:
        return
    lines = ["#### Files with problems", "",
             "| File | Failed | Skipped | Did not finish | File error |",
             "| --- | ---: | ---: | ---: | :---: |"]
    for path, (failed, skipped, unfinished, broken) in sorted(
            rows.items(), key=lambda kv: (-kv[1][3], -kv[1][0], kv[0])):
        lines.append(f"| {cell(path)} | {failed} | {skipped} | {unfinished} | "
                     f"{'yes' if broken else ''} |")
    if out.fits(lines):
        out.add(*lines, "")


# ---------------------------------------------------------------------- main


def _int_or_none(text):
    return int(text) if text and text.strip().isdigit() else None


def _fraction_or_none(text):
    try:
        return Fraction(text.strip()) if text and text.strip() else None
    except (ValueError, ZeroDivisionError):
        return None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("results")
    parser.add_argument("--out", required=True)
    parser.add_argument("--summary-out", default="")
    parser.add_argument("--covered", default="")
    parser.add_argument("--total", default="")
    parser.add_argument("--min-coverage", default="")
    parser.add_argument("--tests-outcome", default="")
    parser.add_argument("--commit", default="")
    parser.add_argument("--repo-url", default="")
    parser.add_argument("--run-url", default="")
    parser.add_argument("--workspace", default=os.getcwd())
    args = parser.parse_args()

    run = parse_events(load_events(args.results), args.workspace)
    coverage = Coverage(_int_or_none(args.covered), _int_or_none(args.total),
                        _fraction_or_none(args.min_coverage))
    ctx = Context(args.commit, args.repo_url.rstrip("/"), args.run_url,
                  args.tests_outcome)

    with open(args.out, "w", encoding="utf-8") as out:
        out.write(render(run, coverage, ctx))
    if args.summary_out:
        with open(args.summary_out, "w", encoding="utf-8") as out:
            out.write(render(run, coverage, ctx, summary=True))

    print(f"passed={len(run.passed)}")
    print(f"failed={len(run.failed)}")
    print(f"skipped={len(run.skipped)}")
    print(f"total={run.total}")
    print(f"file_errors={len(run.file_errors)}")
    print(f"unfinished={len(run.unfinished)}")


if __name__ == "__main__":
    main()
