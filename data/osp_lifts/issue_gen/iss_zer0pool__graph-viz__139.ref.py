"""Reference harness: exercises every public function of iss_zer0pool__graph-viz__139."""
import importlib.util
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "gv139", Path(__file__).parent / "iss_zer0pool__graph-viz__139.py"
)
mod = importlib.util.module_from_spec(spec)
sys.modules["gv139"] = mod
spec.loader.exec_module(mod)

g = mod.LineageGraph()
for n, k in [("raw", "table"), ("stg", "table"), ("mart", "table"), ("etl", "job"), ("agg", "job")]:
    g.add_node(n, k)
g.add_edge("raw", "stg")     # raw feeds stg
g.add_edge("stg", "mart")
g.add_edge("raw", "etl")     # raw feeds job etl
g.add_edge("etl", "mart")

assert g.impact("raw") == ["etl", "mart", "raw", "stg"], g.impact("raw")
assert g.impact("mart", direction="upstream") == ["etl", "mart", "raw", "stg"]
assert g.impact("raw", direction="both") == ["etl", "mart", "raw", "stg"]
assert g.impact("raw", max_depth=1) == ["etl", "raw", "stg"]
grouped = g.impact_by_kind("raw")
assert grouped == {"job": ["etl"], "table": ["mart", "raw", "stg"]}, grouped
assert g.max_fanout("raw") == 2
assert g.max_fanout("mart") == 0

# Diamond: shared downstream node appears once.
d = mod.LineageGraph()
for n in ("a", "b", "c", "shared"):
    d.add_node(n, "table")
for s, t in (("a", "b"), ("a", "c"), ("b", "shared"), ("c", "shared")):
    d.add_edge(s, t)
assert d.impact("a") == ["a", "b", "c", "shared"]
# Adversarial cycle must terminate via revisit skip.
d.add_edge("shared", "a")
assert d.impact("a") == ["a", "b", "c", "shared"]  # finite: revisit skipped

# Errors.
try:
    g.add_node("x", "view")
    raise AssertionError("expected ValueError")
except ValueError:
    pass
try:
    g.add_node("raw", "table")
    raise AssertionError("expected duplicate ValueError")
except ValueError:
    pass
try:
    g.impact("ghost")
    raise AssertionError("expected KeyError")
except KeyError:
    pass

print("graph-viz 139 ref OK")
