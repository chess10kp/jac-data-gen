"""Reference harness: exercises every public function of iss_QuEraComputing__bloqade-circuit__852."""
import importlib.util
import pathlib

_mod_path = pathlib.Path(__file__).parent / "iss_QuEraComputing__bloqade-circuit__852.py"
_spec = importlib.util.spec_from_file_location("bloqade_mod", _mod_path)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
analysis_units = _mod.analysis_units
build_call_graph = _mod.build_call_graph
frame_call_count = _mod.frame_call_count

# The issue's Fibonacci-shaped graph: main -> B, B -> {B, main}.
adj = build_call_graph(
    ["main", "B", "qalloc"],
    [("main", "B"), ("B", "B"), ("B", "main"), ("main", "qalloc")],
)
assert analysis_units(adj, "main", 10) == ["B", "main", "qalloc"]
assert frame_call_count(adj, "main", 10) == 3

# Depth guard: deeper callees return bottom.
chain = build_call_graph(
    ["a", "b", "c", "d"],
    [("a", "b"), ("b", "c"), ("c", "d")],
)
assert analysis_units(chain, "a", 0) == ["a"]
assert analysis_units(chain, "a", 1) == ["a", "b"]
assert analysis_units(chain, "a", 3) == ["a", "b", "c", "d"]

# Diamond: shared callee analyzed once.
diamond = build_call_graph(
    ["check", "calc_a", "calc_b", "leaf"],
    [("check", "calc_a"), ("check", "calc_b"),
     ("calc_a", "leaf"), ("calc_b", "leaf")],
)
assert analysis_units(diamond, "check", 5) == ["calc_a", "calc_b", "check", "leaf"]
assert frame_call_count(diamond, "check", 5) == 4

# Unknown entry / negative depth.
empty = build_call_graph(["solo"], [])
assert analysis_units(empty, "ghost", 4) == []
assert analysis_units(empty, "solo", -1) == []
assert analysis_units(empty, "solo", 0) == ["solo"]

print("bloqade-circuit 852 ref OK")
