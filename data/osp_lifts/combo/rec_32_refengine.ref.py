"""Reference harness for rec_32_refengine (IDE refactor engine). Exit 0."""
import sys

sys.path.insert(0, "/home/jac/repos/jac_llm_data/data/osp_lifts/combo")
from rec_32_refengine import RefactorEngine


def build():
    e = RefactorEngine()
    e.add_scope("mod")
    e.add_scope("cls", parent="mod")
    e.add_scope("meth", parent="cls")
    e.add_scope("func", parent="mod")
    e.define("mod", "config")
    e.define("cls", "config")          # shadows module-level config
    e.define("func", "helper")
    e.add_reference("meth", "config")  # resolves to cls (shadowing)
    e.add_reference("func", "config")
    e.add_reference("mod", "helper")
    return e


def test_add_and_define():
    e = build()
    assert sorted(e.scopes) == ["cls", "func", "meth", "mod"]
    assert e.definitions("config") == ["cls", "mod"]
    try:
        e.add_scope("mod")
        raise AssertionError("expected duplicate scope error")
    except ValueError:
        pass


def test_resolve_shadowing():
    e = build()
    assert e.resolve("meth", "config") == "cls"   # nearest enclosing wins
    assert e.resolve("func", "config") == "mod"
    assert e.resolve("mod", "missing") is None


def test_references_within():
    e = build()
    # subtree of mod includes everything; refs to config: meth, func
    assert e.references_within("mod", "config") == ["func", "meth"]
    # subtree of cls only contains meth
    assert e.references_within("cls", "config") == ["meth"]
    assert e.references_within("func", "config") == ["func"]  # root itself counts


def test_rename_postconditions():
    e = build()
    n = e.rename("helper", "util_fn")
    assert n == 1
    assert e.definitions("util_fn") == ["func"]
    assert e.definitions("helper") == []
    assert e.resolve("func", "util_fn") == "func"


def test_rename_errors():
    e = build()
    try:
        e.rename("helper", "config")
        raise AssertionError("expected collision")
    except ValueError:
        pass
    try:
        e.rename("ghost", "whatever")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass
    assert e.rename("helper", "helper") == 0  # no-op rename


test_add_and_define()
test_resolve_shadowing()
test_references_within()
test_rename_postconditions()
test_rename_errors()
print("rec_32 ref OK")
sys.exit(0)
