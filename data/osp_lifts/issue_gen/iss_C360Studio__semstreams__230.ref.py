import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_C360Studio__semstreams__230",
    Path(__file__).with_name("iss_C360Studio__semstreams__230.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

load_packages = mod.load_packages
reachable_packages = mod.reachable_packages
unverified_coordinates = mod.unverified_coordinates

ST = load_packages(
    [
        ("app", "com.example:app:1.0"),
        ("lib", None),
        ("util", "com.example:util:2.0"),
        ("orphan", None),
    ],
    [("app", "lib"), ("lib", "util")],
)
assert reachable_packages(ST, ["app"]) == ["app", "lib", "util"]
assert unverified_coordinates(ST, ["app"]) == ["lib"]

CYCLE = load_packages(
    [("a", None), ("b", "g:b:1"), ("c", None), ("leaf", "g:l:1")],
    [("a", "b"), ("b", "c"), ("c", "a"), ("c", "leaf")],
)
assert reachable_packages(CYCLE, ["a"]) == ["a", "b", "c", "leaf"]
assert unverified_coordinates(CYCLE, ["a"]) == ["a", "c"]

DIAMOND = load_packages(
    [("root", "r:1"), ("left", None), ("right", None), ("sink", "s:1")],
    [("root", "left"), ("root", "right"), ("left", "sink"), ("right", "sink")],
)
assert unverified_coordinates(DIAMOND, ["root"]) == ["left", "right"]

assert reachable_packages(ST, ["missing"]) == []

print("ok")
