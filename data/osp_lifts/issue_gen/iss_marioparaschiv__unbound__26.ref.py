"""Reference harness: exercises every public function of iss_marioparaschiv__unbound__26."""
import importlib

mod = importlib.import_module("iss_marioparaschiv__unbound__26")
has_cycle = mod.has_cycle
nodes_in_cycles = mod.nodes_in_cycles
layer_violations = mod.layer_violations

# Clean layered graph: api -> managers -> stores -> builtins, no cycles.
clean = {
    "imports": {
        "client": ["user_manager"],
        "user_manager": ["user_store"],
        "user_store": ["deep_clone"],
    },
    "layers": {
        "client": "api",
        "user_manager": "managers",
        "user_store": "stores",
        "deep_clone": "builtins",
    },
}
assert has_cycle(clean) is False
assert nodes_in_cycles(clean) == []
assert layer_violations(clean) == []

# Cross-layer cycle: managers <-> stores. The stores -> managers edge also
# points upward, so it is a layering violation too.
cross = {
    "imports": {"user_manager": ["session_store"], "session_store": ["user_manager"]},
    "layers": {"user_manager": "managers", "session_store": "stores"},
}
assert has_cycle(cross) is True
assert nodes_in_cycles(cross) == ["session_store", "user_manager"]
assert layer_violations(cross) == ["session_store->user_manager"]

# Self-loop: a module importing itself.
self_loop = {"imports": {"util": ["util"]}, "layers": {"util": "builtins"}}
assert has_cycle(self_loop) is True
assert nodes_in_cycles(self_loop) == ["util"]
assert layer_violations(self_loop) == []

# Acyclic diamond: shared store reached by two managers is NOT a cycle.
diamond = {
    "imports": {"app": ["left", "right"], "left": ["shared"], "right": ["shared"]},
    "layers": {"app": "api", "left": "managers", "right": "managers", "shared": "stores"},
}
assert has_cycle(diamond) is False
assert nodes_in_cycles(diamond) == []
assert layer_violations(diamond) == []

# Two disjoint cycles plus an isolated module: all four cyclic modules
# reported, the isolated one not.
multi = {
    "imports": {"a1": ["a2"], "a2": ["a1"], "b1": ["b2"], "b2": ["b1"], "c": []},
    "layers": {"a1": "builtins", "a2": "builtins", "b1": "managers", "b2": "stores", "c": "api"},
}
assert has_cycle(multi) is True
assert nodes_in_cycles(multi) == ["a1", "a2", "b1", "b2"]

# Missing "layers" key: everything defaults to builtins (same layer).
nolayers = {"imports": {"a": ["b"], "b": ["a"]}}
assert has_cycle(nolayers) is True
assert nodes_in_cycles(nolayers) == ["a", "b"]
assert layer_violations(nolayers) == []

# Upward import without a cycle: layering violation only.
up = {"imports": {"store_x": ["api_y"]}, "layers": {"store_x": "stores", "api_y": "api"}}
assert has_cycle(up) is False
assert nodes_in_cycles(up) == []
assert layer_violations(up) == ["store_x->api_y"]

# Dep-only module (never an importer) is probed and found acyclic.
depsonly = {"imports": {"a": ["z"]}, "layers": {"a": "api", "z": "managers"}}
assert has_cycle(depsonly) is False
assert nodes_in_cycles(depsonly) == []
assert layer_violations(depsonly) == []

print("iss_marioparaschiv__unbound__26 ref OK")
