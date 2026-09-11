"""Reference harness for iss_seebom-labs__BOMHort__56."""

from iss_seebom-labs__BOMHort__56 import DependencyGraph


def build_fixture() -> DependencyGraph:
    g = DependencyGraph()
    g.add_component("root", "app")
    g.add_component("a", "lib-a")
    g.add_component("b", "lib-b")
    g.add_component("c", "lib-c")
    g.add_component("d", "shared-d")
    g.add_dependency("root", "a")
    g.add_dependency("root", "b")
    g.add_dependency("a", "c")
    g.add_dependency("b", "d")
    g.add_dependency("c", "d")  # diamond: d reachable via a->c and b
    return g


def build_cycle_fixture() -> DependencyGraph:
    g = DependencyGraph()
    g.add_component("x", "x")
    g.add_component("y", "y")
    g.add_component("z", "z")
    g.add_dependency("x", "y")
    g.add_dependency("y", "z")
    g.add_dependency("z", "x")
    return g


def main() -> None:
    g = build_fixture()
    assert g.direct_dependencies("root") == ["a", "b"]
    assert g.dependency_closure("root") == ["a", "b", "c", "d", "root"]
    assert g.has_cycle() is False
    rows = g.tree_rows("root")
    assert [(d, i) for d, i, _ in rows] == [(0, "root"), (1, "a"), (2, "c"), (3, "d"), (1, "b")]

    cg = build_cycle_fixture()
    assert cg.has_cycle() is True
    assert cg.dependency_closure("x") == ["x", "y", "z"]

    try:
        g.get_name("missing")
    except KeyError:
        pass
    else:
        raise AssertionError("expected KeyError")

    g2 = build_fixture()
    g2.remove_component("a")
    assert g2.direct_dependencies("root") == ["b"]
    assert "a" not in g2.dependency_closure("root")


if __name__ == "__main__":
    main()
