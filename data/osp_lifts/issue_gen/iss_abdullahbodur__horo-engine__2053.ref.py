"""Reference harness for iss_abdullahbodur__horo-engine__2053."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_abdullahbodur__horo-engine__2053.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
v = _mod.WorkflowValidator()
v.set_graph_limit("nodes", 10)
v.add_node("A", {"out": "float"})
v.add_node("B", {"in": "float", "out": "float"})
v.add_node("C", {"in": "float"})
v.add_edge(("A", "out"), ("B", "in"))
v.add_edge(("B", "out"), ("C", "in"))
assert v.validate() == []
assert v.topological_order() == ["A", "B", "C"]

v2 = _mod.WorkflowValidator()
v2.add_node("X", {"o": "int"})
v2.add_node("Y", {"i": "int", "o": "int"})
v2.add_node("Z", {"i": "int"})
v2.add_edge(("X", "o"), ("Y", "i"))
v2.add_edge(("Y", "o"), ("Z", "i"))
v2.add_edge(("Z", "i"), ("X", "o"))
cyc = v2.detect_cycle()
assert cyc is not None
assert v2.validate() == sorted([f"cycle:{'>'.join(cyc)}"])

v3 = _mod.WorkflowValidator()
v3.add_node("N", {"a": "float"})
try:
    v3.add_edge(("N", "a"), ("missing", "a"))
    assert False, "expected dangling edge rejection"
except _mod.GraphValidationError as exc:
    assert str(exc) == "dangling edge"

v4 = _mod.WorkflowValidator()
v4.add_node("P", {"x": "float"})
v4.add_node("Q", {"y": "int"})
try:
    v4.add_edge(("P", "x"), ("Q", "y"))
    assert False, "expected incompatible pin rejection"
except _mod.GraphValidationError as exc:
    assert str(exc) == "incompatible pin"

v5 = _mod.WorkflowValidator()
for i in range(3):
    v5.add_node(f"n{i}", {"o": "float", "i": "float"})
v5.set_graph_limit("nodes", 2)
assert v5.validate() == ["limit:nodes exceeded"]

v6 = _mod.WorkflowValidator()
v6.add_node("M", {"o": "float"})
v6.set_node_budget("M", -1)
assert v6.validate() == ["limit:node:M invalid"]

try:
    v.add_node("A", {"o": "float"})
    assert False, "expected duplicate node rejection"
except _mod.GraphValidationError:
    pass

try:
    v2.topological_order()
    assert False, "expected cycle rejection"
except _mod.GraphValidationError:
    pass
print("iss_abdullahbodur__horo-engine__2053 ref OK")
