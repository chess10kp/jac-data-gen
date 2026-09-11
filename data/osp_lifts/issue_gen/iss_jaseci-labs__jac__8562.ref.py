"""Reference harness for iss_jaseci-labs__jac__8562."""

import importlib.util
from pathlib import Path

MOD_PATH = Path(__file__).with_suffix("").with_suffix(".py")
spec = importlib.util.spec_from_file_location("lift_mod", MOD_PATH)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)


def build_cycle_abc() -> mod.CyclicGraph:
    g = mod.CyclicGraph()
    for n in ("a", "b", "c"):
        g.add_edge("root", n)  # attach via synthetic root edges if needed
    g.add_edge("a", "b")
    g.add_edge("b", "c")
    g.add_edge("c", "a")
    return g


def build_cycle_direct() -> mod.CyclicGraph:
    g = mod.CyclicGraph()
    g.add_edge("a", "b")
    g.add_edge("b", "c")
    g.add_edge("c", "a")
    return g


def build_diamond() -> mod.CyclicGraph:
    g = mod.CyclicGraph()
    g.add_edge("s", "l")
    g.add_edge("s", "r")
    g.add_edge("l", "t")
    g.add_edge("r", "t")
    return g


# --- cycle abc (matches probe: 3 nodes, once each) ---
g1 = build_cycle_direct()
assert mod.count_reachable_dfs(g1, "a") == 3
assert mod.count_reachable_bfs(g1, "a") == 3
assert mod.reachable_nodes(g1, "a") == ["a", "b", "c"]

# --- diamond: shared target, count still 4 ---
g2 = build_diamond()
assert mod.count_reachable_dfs(g2, "s") == 4
assert mod.count_reachable_bfs(g2, "s") == 4
assert mod.reachable_nodes(g2, "s") == ["l", "r", "s", "t"]

# --- unknown start ---
g3 = mod.CyclicGraph()
g3.add_edge("x", "y")
assert mod.count_reachable_dfs(g3, "missing") == 0
assert mod.count_reachable_bfs(g3, "missing") == 0
assert mod.reachable_nodes(g3, "missing") == []

print("ok")
