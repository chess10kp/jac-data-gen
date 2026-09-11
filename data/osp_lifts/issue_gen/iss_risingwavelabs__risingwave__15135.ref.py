import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("mod", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

CHAIN = [(f"n{i}", f"n{i + 1}") for i in range(20)]
DIAMOND = [("d0", "a"), ("d0", "b"), ("a", "t"), ("b", "t")]
CYCLE = [("a", "b"), ("b", "c"), ("c", "a")]

g_chain = mod.build_rcte_graph(CHAIN)
g_diamond = mod.build_rcte_graph(DIAMOND)
g_cycle = mod.build_rcte_graph(CYCLE)

assert mod.stopped_by_iteration_cap(g_chain, "n0") is True
assert mod.cte_ref_reachable(g_chain, "n0") == [f"n{i}" for i in range(17)]

expand = mod.recursive_union_expand(g_diamond, "d0")
assert expand.count("t") == 1
assert mod.cte_ref_reachable(g_diamond, "d0") == sorted(set(expand))

assert mod.cte_ref_reachable(g_cycle, "a") == ["a", "b", "c"]
assert mod.stopped_by_iteration_cap(g_cycle, "a") is False

g_empty = mod.build_rcte_graph([("x", "y")])
assert mod.recursive_union_expand(g_empty, "missing") == []
assert mod.cte_ref_reachable(g_empty, "missing") == []
assert mod.stopped_by_iteration_cap(g_empty, "missing") is False

print("ok")
