import importlib.util
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
MOD = HERE / "iss_algoscope-hq__AlgoScope__838.py"
spec = importlib.util.spec_from_file_location("topo838", MOD)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
sys.modules["topo838"] = mod
spec.loader.exec_module(mod)

TaskGraph = mod.TaskGraph
CycleError = mod.CycleError


def build_fixture() -> TaskGraph:
    g = TaskGraph()
    for t in ("compile", "link", "test", "lint", "package"):
        g.add_task(t)
    g.add_dependency("compile", "link")
    g.add_dependency("link", "test")
    g.add_dependency("compile", "lint")
    g.add_dependency("lint", "package")
    g.add_dependency("test", "package")
    return g


def build_cycle_fixture() -> TaskGraph:
    g = TaskGraph()
    g.add_task("a")
    g.add_task("b")
    g.add_dependency("a", "b")
    g.add_dependency("b", "a")
    return g


def build_diamond_fixture() -> TaskGraph:
    # Adversarial insertion order: edges added so revisit fires before deeper first-visits.
    g = TaskGraph()
    g.add_task("root")
    g.add_task("left")
    g.add_task("right")
    g.add_task("join")
    g.add_dependency("root", "join")
    g.add_dependency("root", "left")
    g.add_dependency("root", "right")
    g.add_dependency("left", "join")
    g.add_dependency("right", "join")
    return g


def main() -> None:
    g = build_fixture()
    k = g.topological_order_kahn()
    d = g.topological_order_dfs()
    assert k == d
    assert k.index("compile") < k.index("link")
    assert k.index("link") < k.index("test")
    assert k.index("lint") < k.index("package")
    assert g.reachable_from("compile") == ["left", "link", "lint", "package", "test"]
    assert g.reachable_from("missing") == []
    assert not g.has_cycle()

    cg = build_cycle_fixture()
    assert cg.has_cycle()
    try:
        cg.topological_order_kahn()
        raise AssertionError("expected CycleError")
    except CycleError:
        pass
    try:
        cg.topological_order_dfs()
        raise AssertionError("expected CycleError")
    except CycleError:
        pass

    dg = build_diamond_fixture()
    order = dg.topological_order_kahn()
    assert order.index("root") < order.index("join")
    assert set(dg.reachable_from("root")) == {"join", "left", "right"}


if __name__ == "__main__":
    main()
