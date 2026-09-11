"""Reference harness: exercises every public function of iss_CatholicOS__ontokit-web__81."""
import importlib.util
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "ok81", Path(__file__).parent / "iss_CatholicOS__ontokit-web__81.py"
)
mod = importlib.util.module_from_spec(spec)
sys.modules["ok81"] = mod
spec.loader.exec_module(mod)

g = mod.OntologyGraph()
for iri, label in [
    ("obo:GO_0003674", "molecular_function"),
    ("obo:GO_0008152", "metabolic process"),
    ("obo:GO_0055114", "oxidation-reduction"),
    ("obo:HP_0000001", "all"),
]:
    g.add_concept(iri, label)
g.add_edge("obo:GO_0055114", "obo:GO_0008152", "subClassOf")
g.add_edge("obo:GO_0008152", "obo:HP_0000001", "subClassOf")
g.add_edge("obo:GO_0055114", "obo:GO_0003674", "seeAlso")

res = g.build_subgraph("obo:GO_0055114")
assert res["nodes"] == [
    "obo:GO_0003674", "obo:GO_0008152", "obo:GO_0055114", "obo:HP_0000001",
], res["nodes"]
assert ("obo:GO_0055114", "obo:GO_0008152", "subClassOf") in res["edges"]
assert ("obo:GO_0055114", "obo:GO_0003674", "seeAlso") in res["edges"]
assert not res["truncated"]

# seeAlso disabled drops the lateral node.
res2 = g.build_subgraph("obo:GO_0055114", include_see_also=False)
assert "obo:GO_0003674" not in res2["nodes"]
assert not res2["truncated"]

# Node budget triggers the truncation flag (wide fan-out under one node).
small = mod.OntologyGraph()
for i in range(6):
    small.add_concept("c{}".format(i))
    if i:
        small.add_edge("c0", "c{}".format(i))
tight = small.build_subgraph("c0", descendants_depth=1, max_nodes=3)
assert tight["nodes"] == ["c0", "c1", "c2"] and tight["truncated"], tight
roomy = small.build_subgraph("c0", descendants_depth=1)
assert roomy["nodes"] == ["c{}".format(i) for i in range(6)]
assert not roomy["truncated"]

# Depth limits hold: seeAlso-style lateral walk limited to one hop.
lat = mod.OntologyGraph()
for c in ("m", "n", "o"):
    lat.add_concept(c)
lat.add_edge("m", "n", "subClassOf")
lat.add_edge("n", "o", "seeAlso")
out2 = lat.build_subgraph("m")
assert out2["nodes"] == ["m", "n", "o"], out2["nodes"]
assert not out2["truncated"]

# Cycle-safe: subClassOf loop terminates.
looped = mod.OntologyGraph()
for c in ("l0", "l1"):
    looped.add_concept(c)
looped.add_edge("l0", "l1")
looped.add_edge("l1", "l0")
out = looped.build_subgraph("l0")
assert out["nodes"] == ["l0", "l1"], out

# Errors.
try:
    g.build_subgraph("missing")
    raise AssertionError("expected KeyError")
except KeyError:
    pass
try:
    g.add_edge("obo:GO_0008152", "obo:HP_0000001", "partOf")
    raise AssertionError("expected ValueError")
except ValueError:
    pass

print("ontokit-web 81 ref OK")
