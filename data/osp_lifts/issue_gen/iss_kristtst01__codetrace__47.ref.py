import importlib.util
from pathlib import Path

mod_path = Path(__file__).with_suffix("").with_suffix(".py")
spec = importlib.util.spec_from_file_location("codetrace47", mod_path)
mod = importlib.util.module_from_spec(spec)
assert spec.loader
spec.loader.exec_module(mod)

TaskDag = mod.TaskDag
CycleError = mod.CycleError


def build_fixture() -> TaskDag:
    g = TaskDag()
    for t in ["a", "b", "c", "d", "e"]:
        g.add_task(t)
    g.add_dependency("b", "a")
    g.add_dependency("c", "a")
    g.add_dependency("d", "b")
    g.add_dependency("d", "c")
    g.add_dependency("e", "d")
    return g


def build_cycle() -> TaskDag:
    g = TaskDag()
    for t in ["x", "y", "z"]:
        g.add_task(t)
    g.add_dependency("y", "x")
    g.add_dependency("z", "y")
    g.add_dependency("x", "z")
    return g


def build_diamond() -> TaskDag:
    # adversarial: shared child, two parents — closure must not double-count
    g = TaskDag()
    for t in ["p1", "p2", "mid", "leaf"]:
        g.add_task(t)
    g.add_dependency("mid", "p1")
    g.add_dependency("mid", "p2")
    g.add_dependency("leaf", "mid")
    return g


g = build_fixture()
assert g.has_cycle() is False
order = g.topological_order()
assert order.index("a") < order.index("b")
assert order.index("a") < order.index("c")
assert order.index("b") < order.index("d")
assert order.index("c") < order.index("d")
assert order.index("d") < order.index("e")
assert sorted(g.ancestors("d")) == ["a", "b", "c"]

cg = build_cycle()
assert cg.has_cycle() is True
try:
    cg.topological_order()
    raise AssertionError("expected CycleError")
except CycleError:
    pass

dg = build_diamond()
assert sorted(dg.ancestors("leaf")) == ["mid", "p1", "p2"]

try:
    g.add_dependency("nope", "a")
    raise AssertionError("expected KeyError")
except KeyError:
    pass

print("ok")
