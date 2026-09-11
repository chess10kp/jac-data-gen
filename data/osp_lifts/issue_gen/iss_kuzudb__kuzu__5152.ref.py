"""Reference harness for iss_kuzudb__kuzu__5152."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_kuzudb__kuzu__5152.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_kuzudb__kuzu__5152.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

KIND_A = _mod.KIND_A
KIND_C = _mod.KIND_C
KIND_ATTR = _mod.KIND_ATTR
fresh_graph_store = _mod.fresh_graph_store
register_node = _mod.register_node
add_pair_hop = _mod.add_pair_hop
two_hop_targets = _mod.two_hop_targets
count_two_hop_a_to_c = _mod.count_two_hop_a_to_c
backward_c_reach = _mod.backward_c_reach
count_backward_c_reach = _mod.count_backward_c_reach
query_row_count = _mod.query_row_count

assert KIND_A == "A"
assert KIND_C == "C"
assert KIND_ATTR == "Attribute"

s0 = fresh_graph_store()
assert isinstance(s0, _mod.GraphStore)
assert count_backward_c_reach("Kùzu", 6, s0) == 0
assert count_two_hop_a_to_c(s0) == 0
assert query_row_count("Kùzu", 6, s0) == 0

s1 = fresh_graph_store()
register_node("kuzu", KIND_C, "Kùzu", s1)
register_node("c_left", KIND_C, "", s1)
register_node("c_right", KIND_C, "", s1)
register_node("hub", KIND_C, "", s1)
register_node("a1", KIND_A, "", s1)
register_node("at1", KIND_ATTR, "", s1)
register_node("at2", KIND_ATTR, "", s1)
add_pair_hop("a1", "at1", "c_left", s1)
add_pair_hop("a1", "at2", "c_right", s1)
add_pair_hop("c_left", "at1", "hub", s1)
add_pair_hop("c_right", "at2", "hub", s1)
add_pair_hop("hub", "at2", "kuzu", s1)
assert sorted(backward_c_reach("kuzu", 6, s1)) == ["c_left", "c_right", "hub", "kuzu"]

s2 = fresh_graph_store()
register_node("a0", KIND_A, "", s2)
try:
    two_hop_targets("ghost", s2)
    raise AssertionError("expected KeyError")
except KeyError:
    pass
try:
    backward_c_reach("ghost", 3, s2)
    raise AssertionError("expected KeyError")
except KeyError:
    pass

s3 = fresh_graph_store()
register_node("kuzu", KIND_C, "Kùzu", s3)
register_node("c1", KIND_C, "", s3)
register_node("a1", KIND_A, "", s3)
register_node("a2", KIND_A, "", s3)
register_node("at1", KIND_ATTR, "", s3)
register_node("at2", KIND_ATTR, "", s3)
register_node("at3", KIND_ATTR, "", s3)
add_pair_hop("c1", "at1", "kuzu", s3)
add_pair_hop("a1", "at2", "c1", s3)
add_pair_hop("a2", "at3", "c1", s3)
assert count_backward_c_reach("Kùzu", 6, s3) == 2
assert count_two_hop_a_to_c(s3) == 2
assert query_row_count("Kùzu", 6, s3) == 2
assert two_hop_targets("a1", s3) == ["c1"]
assert two_hop_targets("a2", s3) == ["c1"]

s4 = fresh_graph_store()
register_node("kuzu", KIND_C, "Kùzu", s4)
register_node("c1", KIND_C, "", s4)
register_node("a1", KIND_A, "", s4)
register_node("at1", KIND_ATTR, "", s4)
add_pair_hop("c1", "at1", "kuzu", s4)
add_pair_hop("a1", "at1", "c1", s4)
explicit = count_two_hop_a_to_c(s4)
joined = query_row_count("Kùzu", 6, s4)
assert explicit == joined
assert explicit == 2
assert two_hop_targets("a1", s4) == ["c1", "kuzu"]

s5 = fresh_graph_store()
register_node("kuzu", KIND_C, "Kùzu", s5)
register_node("c1", KIND_C, "", s5)
register_node("c2", KIND_C, "", s5)
register_node("at1", KIND_ATTR, "", s5)
register_node("at2", KIND_ATTR, "", s5)
add_pair_hop("c2", "at2", "c1", s5)
add_pair_hop("c1", "at1", "kuzu", s5)
assert backward_c_reach("kuzu", 1, s5) == ["kuzu"]
assert backward_c_reach("kuzu", 3, s5) == ["c1", "c2", "kuzu"]

try:
    register_node("dup", KIND_A, "", s5)
    register_node("dup", KIND_C, "", s5)
    raise AssertionError("expected ValueError")
except ValueError:
    pass
try:
    add_pair_hop("ghost", "at1", "kuzu", s5)
    raise AssertionError("expected KeyError")
except KeyError:
    pass

print("iss_kuzudb__kuzu__5152 ref OK")
print("iss_kuzudb__kuzu__5152 ref OK")
