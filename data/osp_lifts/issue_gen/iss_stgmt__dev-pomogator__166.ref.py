"""Reference harness: exercises every public function of iss_stgmt__dev-pomogator__166."""
import importlib

mod = importlib.import_module("iss_stgmt__dev-pomogator__166")
layer_of = mod.layer_of
find_refs = mod.find_refs
impact = mod.impact
impact_by_layer = mod.impact_by_layer

# layer_of: prefix -> layer
assert layer_of("FR-7") == "fr" and layer_of("AC-1") == "ac"
assert layer_of("TASK-2") == "task" and layer_of("TEST-3") == "test"

# Cross-layer chain FR-7 <- AC-1/AC-2 <- SCN-1 (diamond) <- TASK-2 <- FILE-9, TEST-3.
# Edge (from, to, kind): from depends on to. Adversarial order: the shared
# scenario SCN-1 is inserted between AC-2 and AC-1 so revisits of SCN-1's
# parents fire before its deeper first-visit resolution.
edges = [
    ("AC-2", "FR-7", "refs"),
    ("SCN-1", "AC-2", "covers"),
    ("AC-1", "FR-7", "refs"),
    ("SCN-1", "AC-1", "covers"),
    ("TASK-2", "SCN-1", "implements"),
    ("FILE-9", "TASK-2", "step-binding"),
    ("TEST-3", "TASK-2", "tested-by"),
]
res = impact(edges, "FR-7")
assert res == {
    "AC-1": {"depth": 1, "kind": "ac"},
    "AC-2": {"depth": 1, "kind": "ac"},
    "SCN-1": {"depth": 2, "kind": "scn"},
    "TASK-2": {"depth": 3, "kind": "task"},
    "FILE-9": {"depth": 4, "kind": "file"},
    "TEST-3": {"depth": 4, "kind": "test"},
}

# One-hop oracle: find_refs == impact at depth 1 (the issue's oracle test).
assert find_refs(edges, "FR-7") == ["AC-1", "AC-2"]
assert sorted(impact(edges, "FR-7", 1).keys()) == find_refs(edges, "FR-7")
assert find_refs(edges, "TASK-2") == ["FILE-9", "TEST-3"]
assert find_refs(edges, "FR-404") == []

# Depth caps: include at the cap, expand below it.
assert sorted(impact(edges, "FR-7", 2).keys()) == ["AC-1", "AC-2", "SCN-1"]
assert impact(edges, "FR-7", 2)["SCN-1"]["depth"] == 2
assert impact(edges, "FR-7", 0) == {}
assert impact(edges, "SCN-1", 1) == {"TASK-2": {"depth": 1, "kind": "task"}}

# byLayer grouping, sorted per layer.
assert impact_by_layer(edges, "FR-7") == {
    "ac": ["AC-1", "AC-2"],
    "scn": ["SCN-1"],
    "task": ["TASK-2"],
    "file": ["FILE-9"],
    "test": ["TEST-3"],
}
assert impact_by_layer(edges, "SCN-1", 1) == {"task": ["TASK-2"]}

# Shortest chain wins: DEEP reachable directly (d1) and via MID (d2).
asym = [("DEEP", "FR-7", "refs"), ("MID", "FR-7", "refs"), ("DEEP", "MID", "refs")]
res = impact(asym, "FR-7")
assert res["MID"]["depth"] == 1 and res["DEEP"]["depth"] == 1

# Cycles terminate via the visited-depth map.
cyc = [("T2", "T1", "refs"), ("T1", "T2", "refs"), ("T3", "T2", "refs")]
assert impact(cyc, "T1") == {
    "T2": {"depth": 1, "kind": "t2"},
    "T3": {"depth": 2, "kind": "t3"},
}

# Unknown root: empty blast radius.
assert impact(edges, "FR-404") == {}

print("iss_stgmt__dev-pomogator__166 ref OK")
