"""Reference harness: exercises every public function of iss_Aureliolo__synthorg__2841."""
import importlib

mod = importlib.import_module("iss_Aureliolo__synthorg__2841")
materialize = mod.materialize
dependency_closure = mod.dependency_closure

# --- materialize ----------------------------------------------------------
# Two-level decomposition with one deeper branch.
tree = {"plan": ["backend", "frontend"], "backend": ["db"]}
items = {"plan": [], "backend": ["db"], "frontend": ["backend"], "db": []}
out = materialize(tree, items)
assert out["rows"] == [
    {"id": "backend", "parent_id": "plan", "depth": 1},
    {"id": "db", "parent_id": "backend", "depth": 2},
    {"id": "frontend", "parent_id": "plan", "depth": 1},
    {"id": "plan", "parent_id": None, "depth": 0},
]
assert out["max_depth"] == 2

# Depth-3 chain (the measured configuration).
deep_t = {"p": ["a"], "a": ["b"], "b": ["c"]}
deep_i = {"p": [], "a": [], "b": [], "c": []}
out = materialize(deep_t, deep_i)
assert [r["depth"] for r in out["rows"]] == [1, 2, 3, 0]
assert out["max_depth"] == 3

# Adversarial insertion order: the deeper branch (mid -> leaf2) declared
# before the shallower leaf; rows still sort by id, depths stay exact.
adv_t = {"plan": ["mid", "leaf"], "mid": ["leaf2"]}
adv_i = {"plan": [], "mid": [], "leaf": [], "leaf2": []}
out = materialize(adv_t, adv_i)
assert out["rows"] == [
    {"id": "leaf", "parent_id": "plan", "depth": 1},
    {"id": "leaf2", "parent_id": "mid", "depth": 2},
    {"id": "mid", "parent_id": "plan", "depth": 1},
    {"id": "plan", "parent_id": None, "depth": 0},
]
assert out["max_depth"] == 2

# Item the tree never touches: persists with no parent and no depth.
out = materialize({}, {"solo": []})
assert out["rows"] == [{"id": "solo", "parent_id": None, "depth": None}]
assert out["max_depth"] == 0

# Empty plan.
assert materialize({}, {}) == {"rows": [], "max_depth": 0}

# --- dependency_closure ---------------------------------------------------
# Transitive chain.
assert dependency_closure({"a": ["b"], "b": ["c"], "c": []}, "a") == ["b", "c"]
# Leaf closure is empty.
assert dependency_closure({"a": ["b"], "b": []}, "b") == []

# Diamond: d reached via b and via c, closes once.
dia = {"a": ["b", "c"], "b": ["d"], "c": ["d"], "d": []}
assert dependency_closure(dia, "a") == ["b", "c", "d"]

# Cycle: the start rides back into its own closure.
cyc = {"a": ["b"], "b": ["a"]}
assert dependency_closure(cyc, "a") == ["a", "b"]

# Dependency on an id with no depends_on entry of its own.
assert dependency_closure({"a": ["ghost"]}, "a") == ["ghost"]

# Unknown id: the source raises KeyError.
try:
    dependency_closure({"a": []}, "nope")
    raise AssertionError("expected KeyError")
except KeyError:
    pass

print("iss_Aureliolo__synthorg__2841 ref OK")
