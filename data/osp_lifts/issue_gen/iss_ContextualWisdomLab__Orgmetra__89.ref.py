"""Reference harness for ContextualWisdomLab/Orgmetra#89."""

import importlib.util
from pathlib import Path

_MOD = Path(__file__).with_name("iss_ContextualWisdomLab__Orgmetra__89.py")
_spec = importlib.util.spec_from_file_location("orgmetra_89_mod", _MOD)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

load_ruleset = _mod.load_ruleset
required_closure = _mod.required_closure
merge_blockers = _mod.merge_blockers

GATES = [
    "foundation_ci",
    "recovery",
    "security_sast",
    "merge_develop",
]
REQ = [
    ("recovery", "foundation_ci"),
    ("security_sast", "foundation_ci"),
    ("merge_develop", "foundation_ci"),
    ("merge_develop", "recovery"),
    ("merge_develop", "security_sast"),
]

store = load_ruleset(GATES, REQ)
assert required_closure(store, "merge_develop") == [
    "foundation_ci",
    "recovery",
    "security_sast",
]
assert required_closure(store, "missing") == []
assert merge_blockers(store, ["foundation_ci"]) == sorted(GATES)
assert merge_blockers(store, ["recovery"]) == [
    "merge_develop",
    "recovery",
]
assert merge_blockers(store, []) == []

diamond = load_ruleset(
    ["top", "left", "right", "base", "leaf"],
    [
        ("top", "right"),
        ("base", "leaf"),
        ("left", "base"),
        ("top", "left"),
        ("right", "base"),
    ],
)
assert required_closure(diamond, "top") == ["base", "leaf", "left", "right"]

print("orgmetra 89 ref OK")
