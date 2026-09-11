"""Reference harness for stokaro/ptah#1343."""

import importlib.util
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "ptah_mod", HERE / "iss_stokaro__ptah__1343.py"
)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)
SchemaState = mod.SchemaState


def _build_main() -> SchemaState:
    s = SchemaState()
    s.add_object("db", "database")
    s.add_object("public", "schema", "db")
    s.add_object("users", "table", "public")
    s.add_object("orders", "table", "public")
    s.add_object("order_fn", "function", "public")
    s.add_dependency("orders", "users")
    s.add_dependency("order_fn", "orders")
    return s


def main() -> None:
    s = _build_main()
    assert s.parent_chain("users") == ["public", "db"]
    assert s.parent_chain("db") == []
    assert s.parent_chain("missing") == []
    assert s.dependencies_of("orders") == ["users"]
    assert s.dependencies_of("missing") == []
    assert s.transitive_dependencies("order_fn") == ["orders", "users"]
    assert s.transitive_dependencies("users") == []
    assert s.transitive_dependencies("missing") == []
    assert s.migration_order() == ["db", "public", "users", "orders", "order_fn"]

    dup = SchemaState()
    dup.add_object("solo", "table")
    try:
        dup.add_object("solo", "table")
        raise AssertionError("expected duplicate")
    except ValueError:
        pass

    bad_parent = SchemaState()
    bad_parent.add_object("child", "table", "ghost")
    assert bad_parent.parent_chain("child") == []  # never added

    bad_dep = SchemaState()
    bad_dep.add_object("a", "table")
    try:
        bad_dep.add_dependency("a", "missing")
        raise AssertionError("expected KeyError")
    except KeyError:
        pass

  # adversarial diamond: shared reachable before deep first-visit
    d = SchemaState()
    d.add_object("a", "table")
    d.add_object("b", "table")
    d.add_object("shared", "table")
    d.add_object("deep", "table")
    d.add_dependency("a", "shared")
    d.add_dependency("a", "deep")
    d.add_dependency("shared", "deep")
    d.add_dependency("b", "shared")
    assert d.transitive_dependencies("a") == ["deep", "shared"]
    assert d.transitive_dependencies("b") == ["deep", "shared"]

    cyc = SchemaState()
    cyc.add_object("a", "table")
    cyc.add_object("b", "table")
    cyc.add_dependency("a", "b")
    cyc.add_dependency("b", "a")
    assert cyc.migration_order() is None

    print("ok")


if __name__ == "__main__":
    main()
