import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_genfeedai__genfeed_ai__1635",
    Path(__file__).with_name("iss_genfeedai__genfeed_ai__1635.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

load_modules = mod.load_modules
reachable_from_entries = mod.reachable_from_entries
orphan_modules = mod.orphan_modules

G = load_modules(
    ["main", "api", "db", "util", "dead"],
    [("main", "api"), ("api", "db"), ("api", "util"), ("dead", "util")],
)
assert reachable_from_entries(G, ["main"]) == ["api", "db", "main", "util"]
assert orphan_modules(G, ["main"]) == ["dead"]

CYCLE = load_modules(
    ["a", "b", "c", "leaf"],
    [("a", "b"), ("b", "c"), ("c", "a"), ("c", "leaf")],
)
assert reachable_from_entries(CYCLE, ["a"]) == ["a", "b", "c", "leaf"]

DIAMOND = load_modules(
    ["root", "left", "right", "sink"],
    [("root", "left"), ("root", "right"), ("left", "sink"), ("right", "sink")],
)
assert reachable_from_entries(DIAMOND, ["root"]) == ["left", "right", "root", "sink"]

assert reachable_from_entries(G, ["missing"]) == []
assert orphan_modules(G, ["main", "dead"]) == []

print("ok")
