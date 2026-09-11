import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_TheLarkInn__aipm__1531",
    Path(__file__).with_name("iss_TheLarkInn__aipm__1531.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

load_crates = mod.load_crates
transitive_deps = mod.transitive_deps
on_critical_path = mod.on_critical_path

G = load_crates(
    ["workspace", "syn", "jsonschema", "reqwest", "aws-lc-sys"],
    [
        ("workspace", "jsonschema"),
        ("jsonschema", "reqwest"),
        ("reqwest", "aws-lc-sys"),
        ("workspace", "syn"),
    ],
)
assert transitive_deps(G, "workspace") == [
    "aws-lc-sys", "jsonschema", "reqwest", "syn", "workspace"
]
assert on_critical_path(G, ["workspace"], "aws-lc-sys") is True
assert on_critical_path(G, ["workspace"], "missing") is False

CYCLE = load_crates(
    ["a", "b", "c", "leaf"],
    [("a", "b"), ("b", "c"), ("c", "a"), ("c", "leaf")],
)
assert transitive_deps(CYCLE, "a") == ["a", "b", "c", "leaf"]

DIAMOND = load_crates(
    ["root", "left", "right", "sink"],
    [("root", "left"), ("root", "right"), ("left", "sink"), ("right", "sink")],
)
assert transitive_deps(DIAMOND, "root") == ["left", "right", "root", "sink"]

assert transitive_deps(G, "ghost") == []

print("ok")
