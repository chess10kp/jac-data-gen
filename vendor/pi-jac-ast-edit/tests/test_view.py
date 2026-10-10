"""The changed-code view appended to every successful edit (python/edit_view.py)."""
from __future__ import annotations

from conftest import edit

import edit_view


def long_fn(name: str, n: int = 50) -> str:
    body = "\n".join(f"    v{i} = {i};" for i in range(1, n + 1))
    return f"def {name}() -> int {{\n{body}\n    return v1;\n}}\n"


def rib(name, old, new):
    return {"action": "replace_in_body", "target": "function", "name": name, "value": old, "newCode": new}


def test_short_symbol_shown_whole(jac_file):
    p = jac_file("def small() {\n    a = 1;\n}\n", "m.jac")
    res = edit(p, {"action": "add_statement", "target": "function", "name": "small", "newCode": "b = 2;"})
    assert res["report"] == (
        "add_statement ok (lines +1)\n"
        "[m.jac:1-4 function small]\n"
        "def small() {\n    a = 1;\n    b = 2;\n}"
    )


def test_long_symbol_one_change(jac_file):
    p = jac_file("import os;\n\n" + long_fn("big"), "m.jac")
    res = edit(p, rib("big", "v25 = 25;", "v25 = 250;"))
    assert res["report"] == "\n".join([
        "replace_in_body ok",
        "[m.jac:3-55 function big]",
        "def big() -> int {",
        "… 21 unchanged lines (read m.jac:4-24) …",
        "    v22 = 22;", "    v23 = 23;", "    v24 = 24;",
        "    v25 = 250;",
        "    v26 = 26;", "    v27 = 27;", "    v28 = 28;",
        "… 23 unchanged lines (read m.jac:32-54) …",
        "}",
    ])


def test_long_symbol_two_separate_changes(jac_file):
    p = jac_file("import os;\n\n" + long_fn("big"), "m.jac")
    res = edit(p, rib("big", "v10 = 10;", "v10 = 100;"), rib("big", "v40 = 40;", "v40 = 400;"))
    assert res["report"] == "\n".join([
        "2 ops ok (atomic): replace_in_body, replace_in_body",
        "[m.jac:3-55 function big]",
        "def big() -> int {",
        "… 6 unchanged lines (read m.jac:4-9) …",
        "    v7 = 7;", "    v8 = 8;", "    v9 = 9;",
        "    v10 = 100;",
        "    v11 = 11;", "    v12 = 12;", "    v13 = 13;",
        "… 23 unchanged lines (read m.jac:17-39) …",
        "    v37 = 37;", "    v38 = 38;", "    v39 = 39;",
        "    v40 = 400;",
        "    v41 = 41;", "    v42 = 42;", "    v43 = 43;",
        "… 8 unchanged lines (read m.jac:47-54) …",
        "}",
    ])


def test_batch_over_cap(jac_file):
    p = jac_file("".join(long_fn(f"f{k}", 35) + "\n" for k in range(3)), "m.jac")
    body = "\n".join(f"w{i} = {i};" for i in range(30))
    res = edit(p, *[{"action": "set_body", "target": "function", "name": f"f{k}", "newCode": body} for k in range(3)])
    lines = res["report"].split("\n")
    code = [ln for ln in lines[1:] if not ln.startswith(("[", "…"))]
    assert len(code) == edit_view.MAX_LINES
    assert lines[0] == "3 ops ok (atomic): set_body, set_body, set_body (lines -18)"
    assert lines[1] == "[m.jac:1-32 function f0]"
    assert lines[-1] == ("… view capped at 60 lines (next: read m.jac:62-65; "
                         "1 more changed region: m.jac:67-98) …")


def test_change_outside_symbols_shows_context(jac_file):
    p = jac_file("import os;\n\ndef a() {\n    x = 1;\n}\n", "m.jac")
    res = edit(p, {"action": "add_import", "value": "import sys;"})
    assert res["report"] == "add_import ok (lines +1)\n[m.jac:1-5]\nimport os;\nimport sys;\n\ndef a() {\n    x = 1;"


def test_removed_member_shows_owner(jac_file):
    p = jac_file("obj A {\n    has x: int = 1;\n\n    def f() {\n        return;\n    }\n}\n", "m.jac")
    res = edit(p, {"action": "remove", "target": "ability", "name": "A.f"})
    assert res["report"] == "remove ok (lines -4)\n[m.jac:1-3 obj A]\nobj A {\n    has x: int = 1;\n}"


def test_no_change_reported(jac_file):
    p = jac_file()
    res = edit(p, {"action": "add_import", "value": "import os;"})
    assert res["report"] == "add_import ok (no change: already present)"


def test_changed_line_numbers():
    assert edit_view.changed_line_numbers("a\nb\nc", "a\nB\nc\nd") == {2, 4}
