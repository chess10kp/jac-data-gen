"""Reference harness: exercises every public function of iss_PatrickMassot__leanblueprint__78."""
import importlib

mod = importlib.import_module("iss_PatrickMassot__leanblueprint__78")
DepGraph = mod.DepGraph
CycleError = mod.CycleError

g = DepGraph()
for lbl in ["thm1", "thm2", "thm3", "lem1", "lem2", "def1"]:
    g.add_node(lbl)

# acyclic: thm1 uses thm2 and lem1; thm2 uses lem1 and lem2; lem1 uses def1
g.add_edge("thm1", "thm2")
g.add_edge("thm1", "lem1")
g.add_edge("thm2", "lem1")
g.add_edge("thm2", "lem2")
g.add_edge("lem1", "def1")

assert sorted(g.predecessors("thm2")) == ["lem1", "lem2"]
assert sorted(g.predecessors("thm1")) == ["lem1", "thm2"]
assert sorted(g.successors("lem1")) == ["thm1", "thm2"]
assert g.successors("def1") == ["lem1"]

# ancestors: transitive closure over predecessors
assert g.ancestors("thm1") == {"thm2", "lem1", "lem2", "def1"}
assert g.ancestors("lem1") == {"def1"}
assert g.ancestors("def1") == set()
assert g.find_cycle() == []

# unknown labels
for call in (lambda: g.predecessors("nope"), lambda: g.successors("nope"),
             lambda: g.ancestors("nope")):
    try:
        call()
        raise AssertionError("expected KeyError")
    except KeyError:
        pass
try:
    g.add_edge("thm1", "nope")
    raise AssertionError("expected KeyError")
except KeyError:
    pass

# cycle: lem2 uses thm1 closes the loop through thm1 -> thm2 -> lem2 -> thm1
g.add_edge("lem2", "thm1")
try:
    g.ancestors("thm1")
    raise AssertionError("expected CycleError")
except CycleError as e:
    cyc = e.cycle
    assert cyc[0] == cyc[-1]
    assert set(cyc) <= {"thm1", "thm2", "lem2"}
    # consecutive entries are real edges
    for a, b in zip(cyc, cyc[1:]):
        assert b in g.predecessors(a)

# a node whose ancestor walk reaches the cycle also raises
try:
    g.ancestors("lem2")
    raise AssertionError("expected CycleError")
except CycleError:
    pass

# find_cycle reports a valid cycle anywhere
cyc = g.find_cycle()
assert cyc and cyc[0] == cyc[-1]
for a, b in zip(cyc, cyc[1:]):
    assert b in g.predecessors(a)

# a fresh acyclic graph stays clean even after heavy diamond sharing
h = DepGraph()
for lbl in ["a", "b", "c", "d", "e"]:
    h.add_node(lbl)
h.add_edge("a", "b")
h.add_edge("a", "c")
h.add_edge("b", "d")
h.add_edge("c", "d")
h.add_edge("d", "e")
h.add_edge("a", "d")  # diamond plus shortcut; no cycle
assert h.ancestors("a") == {"b", "c", "d", "e"}
assert h.find_cycle() == []

print("iss_PatrickMassot__leanblueprint__78 ref OK")
