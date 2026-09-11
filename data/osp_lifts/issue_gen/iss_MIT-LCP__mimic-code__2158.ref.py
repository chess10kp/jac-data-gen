"""Reference harness for iss_MIT-LCP__mimic-code__2158."""
import importlib.util
from pathlib import Path
_spec = importlib.util.spec_from_file_location("_mod", Path(__file__).with_name("iss_MIT-LCP__mimic-code__2158.py"))
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
g = _mod.make_graph()
_mod.add_concept(g, "urine_output")
_mod.add_concept(g, "kdigo_uo")
_mod.add_concept(g, "kdigo_stages")
_mod.add_dependency(g, "kdigo_uo", "urine_output")
_mod.add_dependency(g, "kdigo_stages", "kdigo_uo")
order = _mod.topological_order(g)
assert order is not None
assert order.index("urine_output") < order.index("kdigo_uo") < order.index("kdigo_stages")
# diamond
g2 = _mod.make_graph()
for c in ["a", "b", "c", "d"]:
    _mod.add_concept(g2, c)
_mod.add_dependency(g2, "b", "a")
_mod.add_dependency(g2, "c", "a")
_mod.add_dependency(g2, "d", "b")
_mod.add_dependency(g2, "d", "c")
ord2 = _mod.topological_order(g2)
assert ord2 is not None
assert ord2.index("a") < ord2.index("b")
assert ord2.index("a") < ord2.index("c")
assert ord2.index("d") > ord2.index("b") and ord2.index("d") > ord2.index("c")
# diamond order independent: reversed insertion same order constraints
g2_rev = _mod.make_graph()
for c in ["d", "c", "b", "a"]:
    _mod.add_concept(g2_rev, c)
_mod.add_dependency(g2_rev, "d", "c")
_mod.add_dependency(g2_rev, "d", "b")
_mod.add_dependency(g2_rev, "c", "a")
_mod.add_dependency(g2_rev, "b", "a")
ord_rev = _mod.topological_order(g2_rev)
assert ord_rev is not None
assert ord_rev.index("a") < ord_rev.index("d")
# cycle detection
g3 = _mod.make_graph()
_mod.add_concept(g3, "x")
_mod.add_concept(g3, "y")
_mod.add_dependency(g3, "y", "x")
try:
    _mod.add_dependency(g3, "x", "y")
    assert False, "should be cycle"
except ValueError as e:
    assert "cycle" in str(e)
assert _mod.find_cycle(g3) is None  # y->x only, no cycle yet
# create cycle manually for find_cycle test via lower level? use new graph
g4 = _mod.make_graph()
_mod.add_concept(g4, "p")
_mod.add_concept(g4, "q")
# force cycle via adj direct manipulation
g4.adj["p"].append("q")
g4.adj["q"].append("p")
g4.in_degree["q"] = 1
g4.in_degree["p"] = 1
assert _mod.topological_order(g4) is None
cyc = _mod.find_cycle(g4)
assert cyc is not None and "p" in cyc and "q" in cyc
# missing prereq
assert _mod.has_missing_prereq(g, "kdigo_stages", "urine_output") is False
assert _mod.has_missing_prereq(g, "kdigo_stages", "sofa") is True
print("iss_MIT-LCP__mimic-code__2158 ref OK")
