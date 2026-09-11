import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_voltrevo__wac__8", Path(__file__).with_name("iss_voltrevo__wac__8.py")
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

cfg = {"kind": "struct", "name": "Config", "fields": [("enabled", "bool")]}
g = mod.load_types(
    {"a": cfg, "b": dict(cfg), "m": {"kind": "struct", "name": "Metres", "fields": []}},
    [],
)
assert mod.same_identity(g, "a", "b")
assert not mod.same_identity(g, "a", "m")
assert mod.type_digest(g, "nope") == ""
assert mod.dependency_closure(g, "nope") == []

g2 = mod.load_types(
    {"root": cfg, "leaf": cfg, "mid": cfg},
    [("root", "child", "mid"), ("mid", "child", "leaf")],
)
assert mod.dependency_closure(g2, "root") == ["leaf", "mid"]

g3 = mod.load_types(
    {"a": cfg, "b": cfg, "c": cfg},
    [("a", "n", "b"), ("b", "n", "c"), ("c", "n", "a"), ("b", "x", "leaf")],
)
assert mod.dependency_closure(g3, "a") == ["b", "c"]

print("ok")
