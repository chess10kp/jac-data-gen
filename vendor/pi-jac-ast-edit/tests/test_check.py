"""Post-edit `jac check` (python/jac_check.py): parsing, new-vs-old
diagnostics, report format, and the real `jac` CLI when it is installed."""
from __future__ import annotations

import shutil

import pytest

from conftest import edit

import jac_check

CANNED = """\
  Checking e.jac...
e.jac FAILED [100%]

=================================== FAILURES ===================================
____________________________________ e.jac _____________________________________
\x1b[31m✖ Error: error[E1002]: Cannot return Literal["x"], expected int\x1b[0m
  --> e.jac:2:5
    1 | def f() -> int {
    2 |     return "x";
      |     ^^^^^^^^^^^
    3 | }
  → run 'jac guide jac-types' for guidance
✖ Error: error[E1055]: No matching overload found for method "__add__" with the given arguments
  --> e.jac:5:14
    4 | with entry {
    5 |     y: int = f() + 1;
      |              ^^^^^^^
    6 | }
help: Often fixed by adding a more specific type annotation.
  → run 'jac guide jac-types' for guidance

================================= failed files =================================
e.jac - 2 errors, 5 warnings
"""


def test_parse_diagnostics():
    d = jac_check.parse_diagnostics(CANNED)
    assert [(x["code"], x["line"], x["col"]) for x in d] == [("E1002", 2, 5), ("E1055", 5, 14)]
    assert d[0]["message"] == 'Cannot return Literal["x"], expected int'
    assert d[0]["source"] == '    return "x";' and d[0]["caret"] == "    ^^^^^^^^^^^"
    assert d[1]["guide"] == "run 'jac guide jac-types' for guidance"


def test_new_diagnostics_is_a_multiset_difference():
    a = {"code": "E1", "message": "m", "line": 3}
    a2 = {"code": "E1", "message": "m", "line": 9}
    b = {"code": "E2", "message": "n", "line": 5}
    assert jac_check.new_diagnostics([a], [a, b]) == [b]
    assert jac_check.new_diagnostics([a], [a, a2], changed_lines={9}) == [a2]
    assert jac_check.new_diagnostics([a, b], [a]) == []


def test_report_format_and_bounds(monkeypatch):
    d = jac_check.parse_diagnostics(CANNED)
    assert jac_check.format_report("e.jac", [], 0, 0) == "jac check: no new errors"
    assert jac_check.format_report("e.jac", [], 2, 1) == "jac check: no new errors (1 fixed, 2 pre-existing errors remain)"
    assert jac_check.format_report("e.jac", d[:1], 2, 0) == "\n".join([
        "jac check: 1 new error (file has 2 total):",
        'error[E1002] e.jac:2:5: Cannot return Literal["x"], expected int',
        '      return "x";',
        "      ^^^^^^^^^^^",
        "  → run 'jac guide jac-types' for guidance",
    ])
    monkeypatch.setenv("JAC_AST_EDIT_CHECK_MAX", "1")
    many = [dict(d[1], message=f"msg {i} " + "x" * 400) for i in range(20)]
    text = jac_check.format_report("e.jac", many, 20, 0)
    assert text.startswith("jac check: 20 new errors:") and "19 more new error(s)" in text
    assert len(text) <= jac_check.MAX_TOTAL_CHARS
    assert jac_check.format_report("e.jac", [], 0, 0, error="timed out after 1s") == "jac check: not run (timed out after 1s)"


def test_disabled_check_adds_nothing(jac_file):
    res = edit(jac_file(), {"action": "rename", "target": "function", "name": "stub", "value": "stub2"})
    assert "jac check" not in res["report"]


needs_jac = pytest.mark.skipif(shutil.which("jac") is None, reason="jac CLI not installed")


@needs_jac
def test_real_check_reports_only_new_errors(jac_file, monkeypatch):
    monkeypatch.setenv("JAC_AST_EDIT_CHECK", "1")
    # the sample already has one error (str + int in `with entry`)
    p = jac_file(name="g.jac")
    res = edit(p, {"action": "add_statement", "target": "function", "name": "add_two", "newCode": 'q: int = "s";'})
    report = res["report"]
    assert "jac check: 1 new error (file has 2 total):" in report
    assert 'error[E1001] g.jac:31:5: Cannot assign Literal["s"] to int' in report
    assert "E1055" not in report  # pre-existing error is not repeated
    assert res["newDiagnostics"] == 1

    # fixing it: baseline comes from the cache of the previous after-check
    res = edit(p, {"action": "replace_in_body", "target": "function", "name": "add_two",
                   "value": 'q: int = "s";', "newCode": "q: int = 1;"})
    assert res["report"].endswith("jac check: no new errors (1 fixed, 1 pre-existing error remains)")


@needs_jac
def test_real_check_timeout_is_reported(jac_file, monkeypatch):
    monkeypatch.setenv("JAC_AST_EDIT_CHECK", "1")
    monkeypatch.setenv("JAC_AST_EDIT_CHECK_TIMEOUT", "0.001")
    res = edit(jac_file(), {"action": "rename", "target": "function", "name": "stub", "value": "stub2"})
    assert res["report"].endswith("jac check: not run (timed out after 0.001s)")


def test_missing_jac_binary_is_reported(jac_file, monkeypatch):
    monkeypatch.setenv("JAC_AST_EDIT_CHECK", "1")
    monkeypatch.setenv("JAC_AST_EDIT_JAC", "/nonexistent/jac")
    res = edit(jac_file(), {"action": "rename", "target": "function", "name": "stub", "value": "stub2"})
    assert res["report"].endswith("jac check: not run (could not run /nonexistent/jac: No such file or directory)")
