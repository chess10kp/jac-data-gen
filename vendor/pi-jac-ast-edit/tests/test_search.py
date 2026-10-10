"""jac_ast_search modes and the text the model sees (engine.format_search)."""
from __future__ import annotations

from conftest import SAMPLE, engine


def search(root, **payload):
    res = engine.cmd_search(root, {"cwd": str(root if root.is_dir() else root.parent), **payload})
    assert "error" not in res, res
    return res, engine.format_search(res)


def project(tmp_path):
    (tmp_path / "pkg").mkdir()
    (tmp_path / "pkg" / "f.jac").write_text(SAMPLE)
    (tmp_path / "tool.py").write_text("def helper():\n    return 'add_two'\n")
    (tmp_path / "node_modules").mkdir()
    (tmp_path / "node_modules" / "x.jac").write_text("def add_two() {}\n")
    return tmp_path


def test_text_mode_reports_enclosing_symbol(tmp_path):
    _, report = search(project(tmp_path), mode="text", query="add_two")
    assert report == "\n".join([
        "3 text matches (scanned 1 file):",
        "  pkg/f.jac:28 [function add_two] def add_two(x: int, y: int) -> int {",
        '  pkg/f.jac:36 [code] print("é" + add_two(1, 2));',
        '  pkg/f.jac:40 [test "adds"] assert add_two(1, 1) == 2;',
    ])


def test_text_mode_smart_case_and_members(tmp_path):
    root = project(tmp_path)
    res, _ = search(root, mode="text", query="self.label")
    assert [(m["line"], m["qualified"]) for m in res["matches"]] == [(18, "Card.show")]
    assert len(search(root, mode="text", query="CARD")[0]["matches"]) == 0
    assert [m["line"] for m in search(root, mode="text", query="card")[0]["matches"]] == [13, 24]


def test_text_mode_other_files_via_glob(tmp_path):
    _, report = search(project(tmp_path), mode="text", query="add_two", pathGlob="**/*.py")
    assert report == "1 text match (scanned 1 file):\n  tool.py:2 return 'add_two'"


def test_text_mode_cap(tmp_path):
    (tmp_path / "many.jac").write_text("with entry {\n" + "    hit = 1;\n" * 80 + "}\n")
    res, report = search(tmp_path, mode="text", query="hit")
    assert len(res["matches"]) == engine.DEFAULT_TEXT_LIMIT and res["truncated"]
    assert report.split("\n")[0] == "50 text matches (scanned 1 file, truncated: narrow the query or raise limit):"
    assert len(search(tmp_path, mode="text", query="hit", limit=5)[0]["matches"]) == 5


def test_outline_of_one_file(tmp_path):
    root = project(tmp_path)
    _, report = search(root / "pkg" / "f.jac", mode="outline")
    lines = report.split("\n")
    assert lines[0] == "17 AST symbol matches (scanned 1 .jac file):"
    assert "  f.jac:1 import import from math { sqrt }" in lines
    assert "  f.jac:13-22 obj Card" in lines and "  f.jac:24-26 impl Card.todo" in lines


def test_outline_capped(tmp_path):
    (tmp_path / "big.jac").write_text("".join(f"glob g{i}: int = {i};\n" for i in range(150)))
    res, _ = search(tmp_path / "big.jac", mode="outline")
    assert len(res["matches"]) == engine.DEFAULT_LIMIT and res["truncated"]


def test_symbol_mode_kind_synonyms_and_no_match_hint(tmp_path):
    root = project(tmp_path)
    res, _ = search(root, kind="method")
    assert {m["qualified"] for m in res["matches"]} == {"Card.show", "Card.todo"}
    res, _ = search(root, kind="archetype")
    assert {m["qualified"] for m in res["matches"]} == {"Card", "Empty"}
    _, report = search(root, query="nothing_here")
    assert "use mode 'text' to search inside bodies" in report


def test_text_mode_needs_query(tmp_path):
    assert engine.cmd_search(tmp_path, {"mode": "text"})["error"]["code"] == "no_query"
