import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_chaoz23__charactercheck__13",
    Path(__file__).with_name("iss_chaoz23__charactercheck__13.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_containers(
    {"form": ["field42"], "field42": ["leaf"], "leaf": []},
    max_depth=8,
)
assert mod.bounded_walk(g, "form") == ["field42", "form", "leaf"]
assert mod.validate_input(g, "form") is None
assert mod.detect_cycles(g, "form") is False

# child-only root (not a dict key) must still validate
g_child = mod.load_containers({"parent": ["child"]})
assert mod.validate_input(g_child, "child") is None
assert mod.bounded_walk(g_child, "child") == ["child"]

# stable failure codes
assert mod.validate_input(g, "") == "invalid_path"
assert mod.validate_input(g, "form/99/missing") == "invalid_path"
assert mod.detect_cycles(g, "ghost") is False
assert mod.bounded_walk(g, "ghost") == []

g_cycle = mod.load_containers(
    {"a": ["b"], "b": ["c"], "c": ["a"]},
    max_depth=16,
)
assert mod.detect_cycles(g_cycle, "a") is True
assert mod.validate_input(g_cycle, "a") == "cycle_detected"

g_deep = mod.load_containers(
    {"a": ["b"], "b": ["c"], "c": ["d"], "d": []},
    max_depth=2,
)
assert mod.validate_input(g_deep, "a") == "depth_exceeded"
assert mod.bounded_walk(g_deep, "a") == ["a", "b", "c"]

# adversarial diamond: cap reachable twice, once-only visit
g_diamond = mod.load_containers(
    {"hub": ["left", "right"], "left": ["cap"], "right": ["cap"], "cap": []},
)
assert mod.bounded_walk(g_diamond, "hub") == ["cap", "hub", "left", "right"]
assert mod.detect_cycles(g_diamond, "hub") is False

print("ok")
