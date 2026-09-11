"""Reference harness for iss_EffortlessMetrics__perl-lsp-swarm__9783."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_EffortlessMetrics__perl-lsp-swarm__9783.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
build_continuation_graph = _mod.build_continuation_graph
reachable_continuations = _mod.reachable_continuations
propagate_continuation_tuples = _mod.propagate_continuation_tuples
flatten_admitted_thenables = _mod.flatten_admitted_thenables
continuation_paths = _mod.continuation_paths

FACTS = [
    {"id": "root", "parent": None, "tuple_f": ("seed",), "tuple_r": None},
    {"id": "then_a", "parent": "root", "edge": "then", "result_f": ("fulfilled",)},
    {"id": "then_b", "parent": "then_a", "edge": "then", "result_f": ("next",)},
    {"id": "catch_x", "parent": "root", "edge": "catch", "result_f": ("recovered",)},
    {"id": "finally_z", "parent": "then_b", "edge": "finally", "result_f": ("ignored",)},
    {"id": "thenable", "parent": "then_a", "edge": "then", "thenable": True, "result_f": ("inner",)},
    {"id": "thenable_leaf", "parent": "thenable", "edge": "then", "result_f": ("flat",)},
    {"id": "reject_root", "parent": None, "tuple_f": (), "tuple_r": ("boom",)},
    {"id": "reject_catch", "parent": "reject_root", "edge": "catch", "result_f": ("handled",)},
]

graph = build_continuation_graph(FACTS)
adj = graph["adj"]
parent = graph["parent"]
meta = graph["meta"]

assert parent["then_a"] == "root"
assert parent["thenable_leaf"] == "thenable"
assert adj["root"] == ["catch_x", "then_a"]
assert adj["then_a"] == ["then_b", "thenable"]

reach = reachable_continuations("root", adj)
assert reach == ["root", "catch_x", "then_a", "then_b", "thenable", "finally_z", "thenable_leaf"]

tuples = propagate_continuation_tuples("root", adj, meta)
assert tuples["root"] == (("seed",), None)
assert tuples["then_a"] == (("fulfilled",), None)
assert tuples["then_b"] == (("next",), None)
assert tuples["catch_x"] == (("seed",), None)
assert tuples["finally_z"] == (("next",), None)
assert tuples["thenable"] == (("inner",), None)
assert tuples["thenable_leaf"] == (("flat",), None)

reject_graph = build_continuation_graph(FACTS)
reject_adj = reject_graph["adj"]
reject_meta = reject_graph["meta"]
reject_tuples = propagate_continuation_tuples("reject_root", reject_adj, reject_meta)
assert reject_tuples["reject_root"] == ((), ("boom",))
assert reject_tuples["reject_catch"] == (("handled",), None)

flat_adj, flattened = flatten_admitted_thenables(adj, meta, {"thenable"})
assert flattened == ["thenable"]
assert flat_adj["then_a"] == ["then_b", "thenable_leaf"]
assert "thenable" not in flat_adj["then_a"]

flat_paths = continuation_paths("root", flat_adj)
assert flat_paths == [
    ("root", "catch_x"),
    ("root", "then_a", "then_b", "finally_z"),
    ("root", "then_a", "thenable_leaf"),
]

diamond_adj = {
    "root": ["left", "right"],
    "left": ["join"],
    "right": ["join"],
    "join": ["left"],
}
diamond_paths = continuation_paths("root", diamond_adj)
assert diamond_paths == [
    ("root", "left", "join", "left"),
    ("root", "right", "join", "left", "join"),
]

diamond_reach = reachable_continuations("root", diamond_adj)
assert diamond_reach == ["root", "left", "right", "join"]
print("iss_EffortlessMetrics__perl-lsp-swarm__9783 ref OK")
