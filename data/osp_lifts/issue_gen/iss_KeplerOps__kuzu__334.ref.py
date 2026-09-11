"""Reference harness for iss_KeplerOps__kuzu__334."""
import importlib.util
from pathlib import Path
_spec = importlib.util.spec_from_file_location("_mod", Path(__file__).with_name("iss_KeplerOps__kuzu__334.py"))
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
g = _mod.make_graph()
_mod.add_node(g, "a1", "A")
_mod.add_node(g, "attr1", "Attribute")
_mod.add_node(g, "c1", "C")
_mod.add_node(g, "c2", "C")
_mod.add_node(g, "kuzu", "C")
_mod.add_edge(g, "a1", "attr1")
_mod.add_edge(g, "attr1", "c1")
_mod.add_edge(g, "c1", "c2")
_mod.add_edge(g, "c2", "kuzu")
# attribute chain vs recursive must agree
assert _mod.count_via_attribute_chain(g, ["a1"]) == 1
assert _mod.count_via_recursive(g, ["a1"]) == 1
assert _mod.k_hop_reachable(g, "a1", 2) == {"c1"}
assert _mod.k_hop_reachable(g, "a1", 1) == {"attr1"}
# k_hop order independent? same result regardless of insertion order
g2 = _mod.make_graph()
_mod.add_node(g2, "c1", "C")
_mod.add_node(g2, "attr1", "Attribute")
_mod.add_node(g2, "a1", "A")
_mod.add_node(g2, "c2", "C")
_mod.add_node(g2, "kuzu", "C")
_mod.add_edge(g2, "a1", "attr1")
_mod.add_edge(g2, "attr1", "c1")
_mod.add_edge(g2, "c1", "c2")
_mod.add_edge(g2, "c2", "kuzu")
assert _mod.count_via_recursive(g2, ["a1"]) == _mod.count_via_recursive(g, ["a1"])
# shortest hops 1..6 backward from kuzu should reach c1, c2, a1 via chain?
reach = _mod.shortest_hops(g, "kuzu", "C")
assert "c1" in reach or "c2" in reach
# cycle
g3 = _mod.make_graph()
_mod.add_node(g3, "x", "A")
_mod.add_node(g3, "y", "Attribute")
_mod.add_edge(g3, "x", "y")
_mod.add_edge(g3, "y", "x")
assert _mod.has_cycle(g3) is True
g4 = _mod.make_graph()
_mod.add_node(g4, "x", "A")
_mod.add_node(g4, "y", "Attribute")
_mod.add_edge(g4, "x", "y")
assert _mod.has_cycle(g4) is False
# missing node returns empty
assert _mod.k_hop_reachable(g, "ghost", 2) == set()
print("iss_KeplerOps__kuzu__334 ref OK")
