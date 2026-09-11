import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_reflective-org__SANDBOX__66",
    Path(__file__).with_name("iss_reflective-org__SANDBOX__66.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_registry(
    {"so2": ["plume"], "plume": ["base"], "base": []},
    {"so2": "auto", "plume": "auto", "base": "auto"},
    {"so2": 1, "plume": 2, "base": 3},
)
assert mod.downstream_closure(g, "base") == ["plume", "so2"]
vals, stale = mod.resolve_change(g, "base", 99)
assert vals["plume"] == "derived(base)"
assert stale == []

g2 = mod.load_registry(
    {"a": ["b"], "b": ["c"], "c": []},
    {"a": "auto", "b": "user_override", "c": "auto"},
    {"a": 1, "b": 2, "c": 3},
)
_, stale2 = mod.resolve_change(g2, "a", 5)
assert stale2 == ["b"]

g3 = mod.load_registry({"x": ["y"], "y": ["x"]}, {}, {})
assert mod.detect_cycle(g3)

print("ok")
