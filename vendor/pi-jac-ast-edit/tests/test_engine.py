"""Edit operations on tests/fixtures/sample.jac: placement, indentation,
symbol resolution and rejection behaviour."""
from __future__ import annotations

import pytest

from conftest import SAMPLE, edit, engine


def apply(jac_file, *ops):
    p = jac_file()
    res = edit(p, *ops)
    return res, p.read_text()


def rejects(jac_file, *ops) -> engine.EditError:
    p = jac_file()
    with pytest.raises(engine.EditError) as ei:
        edit(p, *ops)
    assert p.read_text() == SAMPLE, "a rejected batch must not write"
    return ei.value


# --------------------------------------------------------------- body ops

def test_set_body_function(jac_file):
    _, out = apply(jac_file, {"action": "set_body", "target": "function", "name": "add_two",
                              "newCode": "z = x * y;\nreturn z;"})
    assert "def add_two(x: int, y: int) -> int {\n    z = x * y;\n    return z;\n}" in out


def test_set_body_method_relative_and_absolute_indent(jac_file):
    want = '    def show() -> str {\n        if True {\n            return "x";\n        }\n        return self.label;\n    }'
    for code in ('if True {\n    return "x";\n}\nreturn self.label;',
                 'if True {\n            return "x";\n        }\n        return self.label;'):
        _, out = apply(jac_file, {"action": "set_body", "target": "ability", "name": "Card.show", "newCode": code})
        assert want in out


def test_set_body_empty_braces(jac_file):
    _, out = apply(jac_file, {"action": "set_body", "target": "function", "name": "stub", "newCode": "print(1);"})
    assert "def stub() {\n    print(1);\n}" in out


def test_body_ops_prefer_impl_over_bodyless_declaration(jac_file):
    _, out = apply(jac_file, {"action": "set_body", "target": "ability", "name": "Card.todo", "newCode": "return 2;"})
    assert "    def todo() -> int;\n" in out
    assert "impl Card.todo() -> int {\n    return 2;\n}" in out


def test_add_statement_appends_with_body_indent(jac_file):
    _, out = apply(jac_file, {"action": "add_statement", "target": "function", "name": "add_two",
                              "newCode": "if z > 1 {\n    print(z);\n}"})
    assert "    return z;\n    if z > 1 {\n        print(z);\n    }\n}" in out


@pytest.mark.parametrize("target,name,want", [
    ("ability", "Card.show", "        return self.label;\n        print(1);\n    }"),
    ("impl", "Card.todo", "    return 1;\n    print(1);\n}"),
    ("function", "stub", "def stub() {\n    print(1);\n}"),
    ("test", '"adds"', "    assert add_two(1, 1) == 2;\n    print(1);\n}"),
    ("code", None, '    print("é" + add_two(1, 2));\n    print(1);\n}'),
])
def test_add_statement_targets(jac_file, target, name, want):
    op = {"action": "add_statement", "target": target, "newCode": "print(1);"}
    if name:
        op["name"] = name
    _, out = apply(jac_file, op)
    assert want in out


def test_replace_in_body_exact_whitespace_tolerant_and_pair(jac_file):
    for value in ("z = x + y;", "  z = x  +  y;"):
        _, out = apply(jac_file, {"action": "replace_in_body", "target": "function", "name": "add_two",
                                  "value": value, "newCode": "z = x - y;"})
        assert "    z = x - y;\n    return z;" in out
    _, out = apply(jac_file, {"action": "replace_in_body", "target": "function", "name": "add_two",
                              "value": "z = x", "valueEnd": "return z;", "newCode": "return x + y;"})
    assert "def add_two(x: int, y: int) -> int {\n    return x + y;\n}" in out


def test_replace_in_body_after_non_ascii(jac_file):
    _, out = apply(jac_file, {"action": "replace_in_body", "target": "code",
                              "value": "add_two(1, 2)", "newCode": "add_two(3, 4)"})
    assert 'print("é" + add_two(3, 4));' in out


def test_replace_in_body_archetype(jac_file):
    _, out = apply(jac_file, {"action": "replace_in_body", "target": "obj", "name": "Card",
                              "value": "value: int = 0", "newCode": "value: int = 9"})
    assert "value: int = 9;" in out


def test_replace_in_body_errors(jac_file):
    e = rejects(jac_file, {"action": "replace_in_body", "target": "function", "name": "add_two",
                           "value": "q = 1;", "newCode": "x"})
    assert e.code == "anchor_not_found" and "body of add_two begins" in e.suggestions[0]
    e = rejects(jac_file, {"action": "replace_in_body", "target": "function", "name": "add_two",
                           "value": "z", "newCode": "x"})
    assert e.code == "ambiguous_anchor"


# --------------------------------------------------------- structural ops

def test_add_member_method_and_field(jac_file):
    _, out = apply(jac_file, {"action": "add_member", "target": "obj", "name": "Card",
                              "newCode": 'def hi() -> str {\n    return "hi";\n}'})
    assert '        value: int = 0;\n\n    def hi() -> str {\n        return "hi";\n    }\n' in out
    _, out = apply(jac_file, {"action": "add_member", "target": "obj", "name": "Card", "newCode": "count: int = 5"})
    assert "obj Card(Base) {\n    has count: int = 5;\n\n    has label" in out


def test_add_member_empty_archetype_stays_inside(jac_file):
    _, out = apply(jac_file, {"action": "add_member", "target": "obj", "name": "Empty",
                              "newCode": 'def hi() -> str {\n    return "hi";\n}'})
    assert 'obj Empty {\n    def hi() -> str {\n        return "hi";\n    }\n}' in out
    _, out = apply(jac_file, {"action": "add_member", "target": "obj", "name": "Empty", "newCode": "has n: int = 1;"})
    assert "obj Empty {\n    has n: int = 1;\n}" in out


@pytest.mark.parametrize("code,where", [
    ("def f() -> int {\n    return 1;\n}", "end"),
    ('node Room {\n    has name: str = "";\n}', "end"),
    ("enum Dir {\n    UP,\n    DOWN\n}", "end"),
    ('test "two" {\n    assert True;\n}', "end"),
    ("impl Card.show2() -> str {\n    return \"\";\n}", "end"),
    ("glob X: int = 1;", "top"),
    ("type Num = int | float;", "top"),
])
def test_add_declaration(jac_file, code, where):
    _, out = apply(jac_file, {"action": "add_declaration", "newCode": code})
    assert code in out
    if where == "end":
        assert out.rstrip().endswith(code)
    else:
        assert out.index(code) < out.index("enum Color")


def test_add_import_merges_and_is_idempotent(jac_file):
    _, out = apply(jac_file, {"action": "add_import", "value": "import from math { floor, sqrt };"})
    assert "import from math { sqrt, floor }" in out
    _, out = apply(jac_file, {"action": "add_import", "value": "import os;"})
    assert out == SAMPLE
    _, out = apply(jac_file, {"action": "add_import", "value": "import sys;"})
    assert "import os;\nimport sys;\n" in out


def test_micro_ops(jac_file):
    cases = [
        ({"action": "rename", "target": "function", "name": "add_two", "value": "add2"}, "def add2(x: int, y: int)"),
        ({"action": "set_initializer", "target": "has", "name": "Card.value", "value": "52"}, "value: int = 52;"),
        ({"action": "set_return_type", "target": "function", "name": "add_two", "value": "float"}, ") -> float {"),
        ({"action": "set_type", "target": "has", "name": "Card.label", "value": "string"}, "has label: string ="),
        ({"action": "add_parameter", "target": "function", "name": "add_two", "value": "w: int = 0"},
         "def add_two(x: int, y: int, w: int = 0)"),
        ({"action": "remove_parameter", "target": "function", "name": "add_two", "value": "y"}, "def add_two(x: int) ->"),
        ({"action": "set_extends", "target": "obj", "name": "Card", "value": "A, B"}, "obj Card(A, B) {"),
        ({"action": "remove_import", "value": "os"}, "import from math { sqrt }\n\n"),
    ]
    for op, want in cases:
        _, out = apply(jac_file, op)
        assert want in out, op


def test_remove_method(jac_file):
    _, out = apply(jac_file, {"action": "remove", "target": "ability", "name": "Card.show"})
    assert "def show" not in out and "def todo() -> int;" in out


# ------------------------------------------------------------- resolution

def test_archetype_kinds_are_interchangeable(jac_file):
    _, out = apply(jac_file, {"action": "rename", "target": "walker", "name": "Card", "value": "Card2"})
    assert "obj Card2(Base) {" in out


def test_non_body_ops_prefer_declaration_over_impl(jac_file):
    _, out = apply(jac_file, {"action": "rename", "target": "ability", "name": "Card.todo", "value": "todo2"})
    assert "def todo2() -> int;" in out and "impl Card.todo()" in out


def test_ambiguous_symbol_lists_indexes(jac_file):
    p = jac_file(SAMPLE + "\nwith entry {\n    print(3);\n}\n")
    with pytest.raises(engine.EditError) as ei:
        edit(p, {"action": "remove", "target": "code"})
    assert ei.value.code == "ambiguous_symbol"
    assert ei.value.suggestions[:2] == ["index=0: code code (line 35)", "index=1: code code (line 43)"]
    edit(p, {"action": "remove", "target": "code", "index": 1})
    assert "print(3)" not in p.read_text()


def test_miss_reports_real_kind_or_did_you_mean(jac_file):
    e = rejects(jac_file, {"action": "set_initializer", "target": "has", "name": "Card.show", "value": "1"})
    assert e.suggestions[0] == "exists as: ability Card.show (line 17) -> use target='ability'"
    e = rejects(jac_file, {"action": "rename", "target": "function", "name": "add_tw", "value": "q"})
    assert e.suggestions[0] == 'Did you mean: "add_two"?'


def test_syntax_regression_rejected_with_diff(jac_file):
    e = rejects(jac_file, {"action": "set_body", "target": "function", "name": "add_two", "newCode": "return (;"})
    assert e.code == "syntax_regressed" and "+    return (;" in e.suggestions[0]


def test_batch_is_atomic(jac_file):
    rejects(jac_file,
            {"action": "rename", "target": "function", "name": "add_two", "value": "add2"},
            {"action": "rename", "target": "function", "name": "nope", "value": "x"})


def test_symbols_listed_once_per_node():
    syms = engine._symbol_payload(SAMPLE.encode())["symbols"]
    kinds = [(s["kind"], s["qualified"]) for s in syms if s["kind"] != "import"]
    assert len(kinds) == len(set(kinds))
    assert ("obj", "Card") in kinds and ("ability", "Card.show") in kinds and ("function", "add_two") in kinds


def test_reindent():
    assert engine._reindent("a;\nif x {\n    b;\n}", "    ") == "    a;\n    if x {\n        b;\n    }"
    assert engine._reindent("a;\n        b;", "    ") == "    a;\n    b;"
    assert engine._reindent("        a;\n            b;", "  ") == "  a;\n      b;"
    assert engine._reindent("\n\n", "    ") == ""
