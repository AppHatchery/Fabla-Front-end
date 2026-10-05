#!/usr/bin/env python3
"""Tests for test_summary.py. Run: python3 .github/scripts/tests/test_summary_test.py

The events below copy the shapes `flutter test --file-reporter json:` emits,
including the awkward ones: a file that fails to compile, a failing setUpAll,
an error after a test completed, a widget test whose details are only printed,
and a run that was killed part-way.
"""
import os
import sys
import unittest
from fractions import Fraction

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import test_summary as ts  # noqa: E402

WS = "/home/runner/work/app/app"


def suite(sid, path):
    return {"type": "suite", "suite": {"id": sid, "platform": "vm", "path": f"{WS}/{path}"}}


def start(tid, name, sid, path=None, line=None, root_line=None, skip_reason=None):
    widget = root_line is not None
    test = {
        "id": tid, "name": name, "suiteID": sid,
        "metadata": {"skip": skip_reason is not None, "skipReason": skip_reason},
        "line": 174 if widget else line,
        "url": ("package:flutter_test/src/widget_tester.dart" if widget
                else f"file://{WS}/{path}" if path else None),
    }
    if widget:
        test["root_line"] = root_line
        test["root_url"] = f"file://{WS}/{path}"
    return {"type": "testStart", "test": test}


def loader(tid, sid, path):
    return start(tid, f"loading {WS}/{path}", sid)


def done(tid, result="success", skipped=False, hidden=False):
    return {"type": "testDone", "testID": tid, "result": result,
            "skipped": skipped, "hidden": hidden}


def error(tid, message, stack=""):
    return {"type": "error", "testID": tid, "error": message,
            "stackTrace": stack, "isFailure": True}


def printed(tid, message):
    return {"type": "print", "testID": tid, "messageType": "print", "message": message}


def finished(success=True):
    return {"type": "done", "success": success}


def run_of(*events):
    for index, event in enumerate(events):
        event["time"] = (index + 1) * 10
    return ts.parse_events(events, WS)


def passing_file(sid=0, path="test/a_test.dart", count=2, first_id=10):
    events = [suite(sid, path), loader(first_id, sid, path), done(first_id, hidden=True)]
    for n in range(count):
        tid = first_id + 1 + n
        events += [start(tid, f"passes {n}", sid, path, line=5 + n), done(tid)]
    return events


GATE = ts.Coverage(3100, 12611, Fraction(24))
NO_COVERAGE = ts.Coverage()


def render(run, coverage=GATE, summary=False, **ctx):
    return ts.render(run, coverage, ts.Context(**ctx), summary=summary)


class Verdict(unittest.TestCase):
    def test_a_passing_run_says_passed_with_counts_and_coverage(self):
        report = render(run_of(*passing_file(), finished()))
        self.assertTrue(report.startswith("### ✅ Unit & Widget Tests passed"))
        self.assertIn("2 passed · 0 failed · 0 skipped", report)
        self.assertIn("Coverage: **24.58%** (3100 of 12611 lines) · 73 lines above the 24% gate",
                      report)

    def test_low_coverage_fails_even_when_every_test_passes(self):
        report = render(run_of(*passing_file(), finished()), ts.Coverage(3021, 12611, Fraction(24)))
        self.assertTrue(report.startswith("### ❌ Unit & Widget Tests failed"))

    def test_an_error_after_completion_fails_the_test(self):
        path = "test/late_test.dart"
        run = run_of(suite(0, path), start(1, "emits after close", 0, path, line=4), done(1),
                     error(1, "Bad state: Cannot emit new states after calling close",
                           f"{path} 22:66  main.<fn>.<fn>"),
                     finished(False))
        report = render(run)
        self.assertEqual(len(run.failed), 1)
        self.assertTrue(report.startswith("### ❌"))
        self.assertIn("failed after it had completed", report)
        self.assertIn("Cannot emit new states", report)

    def test_a_killed_run_lists_the_test_that_never_finished(self):
        path = "test/recorder_test.dart"
        run = run_of(*passing_file(0, path), start(20, "hangs on the recorder", 0, path, line=9))
        report = render(run)
        self.assertTrue(report.startswith("### ❌"))
        self.assertIn("The test run stopped before it finished.", report)
        self.assertIn("#### 1 test did not finish", report)
        self.assertIn("`hangs on the recorder` · `test/recorder_test.dart:9` · still running when the run stopped", report)

    def test_a_failed_step_with_no_failing_test_is_called_out(self):
        report = render(run_of(*passing_file(), finished(True)), tests_outcome="failure")
        self.assertTrue(report.startswith("### ❌"))
        self.assertIn("Flutter test failed without a failing test.", report)

    def test_no_results_at_all(self):
        report = render(ts.parse_events([], WS), NO_COVERAGE)
        self.assertTrue(report.startswith("### ❌"))
        self.assertIn("No test results were found.", report)


class Failures(unittest.TestCase):
    def test_the_whole_matcher_message_and_the_assertion_line_are_shown(self):
        path = "test/battery_test.dart"
        run = run_of(suite(0, path), start(1, "warns below 20%", 0, path, line=8),
                      error(1, "Expected: true\n  Actual: <false>\nbattery warning should fire\n",
                            "package:matcher  expect\n"
                            "package:flutter_test/src/widget_tester.dart 473:18  expect\n"
                            f"{path} 9:5  main.<fn>\n"),
                      done(1, "failure"), finished(False))
        report = render(run, commit="abc1234def", repo_url="https://github.com/o/r")
        self.assertIn("Actual: <false>", report)
        self.assertIn("battery warning should fire", report)
        self.assertIn("[`test/battery_test.dart:9`](https://github.com/o/r/blob/abc1234def/"
                      "test/battery_test.dart#L9)", report)
        self.assertIn("Results for `abc1234`", report)

    def test_a_widget_failure_shows_the_printed_exception_not_see_logs_above(self):
        path = "test/diary_page_test.dart"
        exception = (
            "══╡ EXCEPTION CAUGHT BY FLUTTER TEST FRAMEWORK ╞════\n"
            "The following TestFailure was thrown running a test:\n"
            "Expected: exactly one matching candidate\n"
            '  Actual: _TextWidgetFinder:<Found 0 widgets with text "Save": []>\n'
            "   Which: means none were found but one was expected\n\n"
            "When the exception was thrown, this was the stack:\n"
            f"#4      main.<anonymous closure> (file://{WS}/{path}:7:5)\n"
            "The test description was:\n  shows Save\n════")
        run = run_of(suite(0, path), start(1, "shows Save", 0, path, root_line=5),
                     printed(1, exception),
                     error(1, "Test failed. See exception logs above.\n"
                              "The test description was: shows Save"),
                     done(1, "error"), finished(False))
        report = render(run)
        self.assertIn("Which: means none were found but one was expected", report)
        self.assertNotIn("See exception logs above", report)
        self.assertNotIn("When the exception was thrown", report)
        self.assertIn("`test/diary_page_test.dart:7`", report)

    def test_a_long_expected_list_cannot_push_actual_out(self):
        path = "test/list_test.dart"
        items = "\n".join(f"            {n}," for n in range(100))
        message = (f"Expected: [\n{items}\n          ]\n"
                   f"  Actual: [\n{items}\n          ]\n"
                   "   Which: at location [24] is <25> instead of <24>\n")
        run = run_of(suite(0, path), start(1, "lists", 0, path, line=3),
                     error(1, message), done(1, "failure"), finished(False))
        block = render(run).split("#### 1 failing test", 1)[1]
        self.assertIn("  Actual: [", block)
        self.assertIn("Which: at location [24] is <25> instead of <24>", block)
        self.assertNotIn("40,", block)
        self.assertIn("…", block)

    def test_long_errors_without_matcher_parts_are_capped(self):
        path = "test/log_test.dart"
        message = "\n".join(f"log line {n}" for n in range(100))
        run = run_of(suite(0, path), start(1, "logs", 0, path, line=3),
                     error(1, message), done(1, "error"), finished(False))
        block = render(run).split("#### 1 failing test", 1)[1]
        self.assertIn("log line 19", block)
        self.assertNotIn("log line 20", block)
        self.assertIn("…", block)

    def test_the_comment_opens_the_first_five_and_folds_the_rest(self):
        path = "test/many_test.dart"
        events = [suite(0, path)]
        for n in range(8):
            events += [start(n + 1, f"case {n}", 0, path, line=n + 1),
                       error(n + 1, "Expected: <1>\n  Actual: <2>"), done(n + 1, "failure")]
        run = run_of(*events, finished(False))
        comment, summary = render(run), render(run, summary=True)
        self.assertIn("<summary>Show 3 more failing tests</summary>", comment)
        self.assertLess(comment.index("`case 4`"), comment.index("<details>"))
        self.assertGreater(comment.index("`case 5`"), comment.index("<details>"))
        self.assertNotIn("more failing test", summary)

    def test_thousands_of_failures_stay_within_the_size_limits(self):
        path = "test/huge_test.dart"
        events = [suite(0, path)]
        for n in range(3000):
            events += [start(n + 1, f"case {n} " + "x" * 80, 0, path, line=n + 1),
                       error(n + 1, ("Expected: something long\n" * 14) + "end"),
                       done(n + 1, "failure")]
        run = run_of(*events, finished(False))
        comment = render(run)
        summary = render(run, summary=True)
        self.assertLessEqual(len(comment.encode()), ts.COMMENT_LIMIT)
        self.assertLessEqual(len(summary.encode()), ts.SUMMARY_LIMIT)
        self.assertIn("not shown to stay within GitHub's size limit", comment)
        self.assertEqual(comment.count("<details>"), comment.count("</details>"))


class FileLevelFailures(unittest.TestCase):
    def test_a_compile_error_is_a_file_failure_with_the_compiler_message(self):
        path = "test/broken_test.dart"
        run = run_of(*passing_file(), suite(1, path), loader(20, 1, path),
                     error(20, f'Failed to load "{WS}/{path}":\n'
                               f"Compilation failed for testPath={WS}/{path}: "
                               f"{path}:5:19: Error: A value of type 'String' can't be "
                               "assigned to a variable of type 'int'."),
                     done(20, "error"), finished(False))
        report = render(run)
        self.assertEqual(len(run.file_errors), 1)
        self.assertEqual(len(run.failed), 0)
        self.assertIn("2 passed · 0 failed · 0 skipped · 1 file error", report)
        self.assertIn("**`test/broken_test.dart`** · failed to load", report)
        self.assertIn("can't be assigned to a variable of type 'int'", report)
        self.assertNotIn(WS, report)

    def test_a_failing_set_up_all_is_a_file_failure_not_a_test(self):
        path = "test/store_test.dart"
        run = run_of(suite(0, path), start(1, "(setUpAll)", 0, path, line=4),
                     error(1, "Bad state: ObjectBox store failed to open", f"{path} 4:17  main"),
                     done(1, "error"), finished(False))
        report = render(run, summary=True)
        self.assertEqual(run.total, 0)
        self.assertIn("**`test/store_test.dart`** · `setUpAll` failed", report)
        self.assertNotIn("Slowest tests", report)

    def test_a_test_named_loading_is_still_a_test(self):
        path = "test/spinner_test.dart"
        run = run_of(suite(0, path), start(1, "loading spinner shows", 0, path, line=3),
                     done(1), finished())
        self.assertEqual(len(run.passed), 1)
        self.assertEqual(run.file_errors, [])


class Coverage(unittest.TestCase):
    def test_the_gate_uses_exact_line_counts_not_lcov_rounding(self):
        # 3021/12611 is 23.955%, which lcov prints as 24.0%.
        below = ts.Coverage(3021, 12611, Fraction(24))
        self.assertFalse(below.passes)
        self.assertIn("**23.95%** (3021 of 12611 lines) · **6 more lines needed** for the 24% gate",
                      ts.coverage_line(below))
        at = ts.Coverage(3027, 12611, Fraction(24))
        self.assertTrue(at.passes)
        self.assertIn("**24.00%** (3027 of 12611 lines) · exactly at the 24% gate",
                      ts.coverage_line(at))

    def test_missing_coverage_fails_instead_of_showing_zero(self):
        missing = ts.Coverage(None, None, Fraction(24))
        self.assertFalse(missing.passes)
        self.assertIn("**not measured**", ts.coverage_line(missing))
        report = render(run_of(*passing_file(), finished()), missing)
        self.assertTrue(report.startswith("### ❌"))
        self.assertNotIn("0.00%", report)

    def test_a_fractional_gate(self):
        self.assertIn("24.5% gate", ts.coverage_line(ts.Coverage(3090, 12611, Fraction("24.5"))))


class Display(unittest.TestCase):
    def test_skips_are_listed_with_their_reason_and_do_not_count_as_failures(self):
        path = "test/flaky_test.dart"
        run = run_of(*passing_file(), suite(1, path),
                     start(20, "uploads", 1, path, line=12, skip_reason="flaky on CI"),
                     done(20, skipped=True), finished())
        report = render(run)
        self.assertTrue(report.startswith("### ✅"))
        self.assertIn("2 passed · 0 failed · 1 skipped", report)
        self.assertIn("- `uploads` · `test/flaky_test.dart:12` · flaky on CI", report)

    def test_markdown_in_names_and_errors_cannot_break_the_layout(self):
        path = "test/escape_test.dart"
        run = run_of(suite(0, path),
                     start(1, "parses `null body | <details> tag", 0, path, line=3),
                     error(1, "Bad state: bad body:\n```\n</details>\n| a | b |"),
                     done(1, "error"), finished(False))
        report = render(run, summary=True)
        self.assertIn("``parses `null body | <details> tag``", report)
        self.assertIn("````\nBad state: bad body:\n```\n</details>\n| a | b |\n````", report)

    def test_the_summary_lists_only_files_with_problems(self):
        path = "test/bad_test.dart"
        run = run_of(*passing_file(), suite(1, path), start(20, "breaks", 1, path, line=2),
                     error(20, "Expected: <1>\n  Actual: <2>"), done(20, "failure"),
                     finished(False))
        summary = render(run, summary=True)
        self.assertIn("| ``test/bad_test.dart`` | 1 | 0 | 0 |  |".replace("``", "`"), summary)
        self.assertNotIn("test/a_test.dart` | 0", summary)
        self.assertIn("#### Slowest tests", summary)
        self.assertNotIn("Run details", summary)
        self.assertNotIn("Slowest tests", render(run))

    def test_a_clean_summary_has_no_problem_files_table(self):
        summary = render(run_of(*passing_file(), finished()), summary=True)
        self.assertNotIn("Files with problems", summary)


if __name__ == "__main__":
    unittest.main(verbosity=1)
