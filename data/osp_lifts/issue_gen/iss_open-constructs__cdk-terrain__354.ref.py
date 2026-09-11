"""Reference harness: exercises every public function of iss_open-constructs__cdk-terrain__354."""
import importlib

mod = importlib.import_module("iss_open-constructs__cdk-terrain__354")
leaves_under = mod.leaves_under
synth_dependencies = mod.synth_dependencies

tree = {
    "stack": ["stack/api", "stack/db"],
    "stack/api": ["stack/api/handler", "stack/api/gw"],
    "stack/api/handler": [],
    "stack/api/gw": [],
    "stack/db": ["stack/db/table"],
    "stack/db/table": [],
    "stack/shared": [],
}

# leaves_under: leaves beneath mid-level constructs, a leaf construct, the root
assert leaves_under(tree, "stack/api") == ["stack/api/gw", "stack/api/handler"]
assert leaves_under(tree, "stack/db") == ["stack/db/table"]
assert leaves_under(tree, "stack/shared") == ["stack/shared"]
assert leaves_under(tree, "stack") == [
    "stack/api/gw", "stack/api/handler", "stack/db/table",
]

# single declaration: N x M cross product of leaves
res = synth_dependencies(tree, [("stack/api", "stack/db")])
assert res == {
    "stack/api/gw": ["stack/db/table"],
    "stack/api/handler": ["stack/db/table"],
}

# fan-out union: two declarations from the same source union their targets
res = synth_dependencies(tree, [("stack/api", "stack/db"), ("stack/api/handler", "stack/shared")])
assert res == {
    "stack/api/gw": ["stack/db/table"],
    "stack/api/handler": ["stack/db/table", "stack/shared"],
}

# diamond-shaped child lists: the shared child is swept once (seen set)
diamond = {
    "r": ["r/a", "r/b"],
    "r/a": ["r/shared", "r/leaf_a"],
    "r/b": ["r/shared", "r/leaf_b"],
    "r/shared": [],
    "r/leaf_a": [],
    "r/leaf_b": [],
}
assert leaves_under(diamond, "r") == ["r/leaf_a", "r/leaf_b", "r/shared"]
res = synth_dependencies(diamond, [("r/a", "r/b")])
assert res == {
    "r/leaf_a": ["r/leaf_b", "r/shared"],
    "r/shared": ["r/leaf_b"],
}

# dependency on an ancestor: self pairs are skipped, no resource depends on itself
res = synth_dependencies(tree, [("stack/api", "stack")])
assert res == {
    "stack/api/gw": ["stack/api/handler", "stack/db/table"],
    "stack/api/handler": ["stack/api/gw", "stack/db/table"],
}

# leaves with no gained dependency are omitted; empty deps synth nothing
res = synth_dependencies(tree, [("stack/db/table", "stack/shared")])
assert res == {"stack/db/table": ["stack/shared"]}
assert synth_dependencies(tree, []) == {}

# unknown construct endpoint fails synth with KeyError (not silently dropped)
try:
    leaves_under(tree, "stack/ghost")
    assert False, "expected KeyError"
except KeyError:
    pass
try:
    synth_dependencies(tree, [("stack/api", "stack/ghost")])
    assert False, "expected KeyError"
except KeyError:
    pass

print("iss_open-constructs__cdk-terrain__354 ref OK")
