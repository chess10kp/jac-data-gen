"""Reference harness for rodri-oliveira-dev/complexity-analyzers#36."""

import importlib.util
from pathlib import Path

_MOD = Path(__file__).with_name("iss_rodri-oliveira-dev__complexity-analyzers__36.py")
_spec = importlib.util.spec_from_file_location("complexity_analyzers_36_mod", _MOD)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

load_analyzers = _mod.load_analyzers
execution_waves = _mod.execution_waves
required_analyzers = _mod.required_analyzers

ANALYZERS = [
    "cyclomatic",
    "cognitive",
    "halstead",
    "maintainability",
    "report",
]
REQ = [
    ("cognitive", "cyclomatic"),
    ("halstead", "cyclomatic"),
    ("maintainability", "cognitive"),
    ("maintainability", "halstead"),
    ("report", "maintainability"),
]

store = load_analyzers(ANALYZERS, REQ)
assert execution_waves(store) == [
    ["cyclomatic"],
    ["cognitive", "halstead"],
    ["maintainability"],
    ["report"],
]
assert required_analyzers(store, "report") == [
    "cognitive",
    "cyclomatic",
    "halstead",
    "maintainability",
]
assert required_analyzers(store, "missing") == []

cycle = load_analyzers(["a", "b", "c"], [("a", "b"), ("b", "c"), ("c", "a")])
assert execution_waves(cycle) is None

diamond = load_analyzers(
    ["top", "left", "right", "base", "leaf"],
    [
        ("top", "right"),
        ("base", "leaf"),
        ("left", "base"),
        ("top", "left"),
        ("right", "base"),
    ],
)
assert required_analyzers(diamond, "top") == ["base", "leaf", "left", "right"]

print("complexity-analyzers 36 ref OK")
