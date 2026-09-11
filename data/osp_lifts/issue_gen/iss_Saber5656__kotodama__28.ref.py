#!/usr/bin/env python3
"""Reference harness for iss_Saber5656__kotodama__28.py"""

import importlib.util
from pathlib import Path

_MOD = Path(__file__).with_name("iss_Saber5656__kotodama__28.py")
spec = importlib.util.spec_from_file_location("iss_Saber5656__kotodama__28", _MOD)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

STAGES = ["capture", "asr", "format_seibun", "format_keigo"]
DEPS = [
    ("asr", "capture"),
    ("format_seibun", "asr"),
    ("format_keigo", "format_seibun"),
]
BUDGETS = {"capture": 150, "asr": 500, "format_seibun": 200, "format_keigo": 200}

bench = mod.KotodamaBench()
bench.load(STAGES, DEPS, BUDGETS)

assert bench.prerequisite_closure("format_keigo") == [
    "asr",
    "capture",
    "format_seibun",
]
assert bench.prerequisite_closure("asr") == ["capture"]
assert bench.prerequisite_closure("capture") == []
assert bench.prerequisite_closure("missing") == []

assert bench.runnable(set()) == ["capture"]
assert bench.runnable({"capture"}) == ["asr"]
assert bench.runnable({"capture", "asr"}) == ["format_seibun"]
assert bench.runnable({"capture", "asr", "format_seibun"}) == ["format_keigo"]
assert bench.runnable(set(STAGES)) == []

assert bench.over_budget({"capture": 160, "asr": 400}) == ["capture"]
assert bench.over_budget({"capture": 100, "asr": 400}) == []

# diamond: merge sink wired before hub arms (adversarial insertion order)
diamond = mod.KotodamaBench()
diamond.load(
    ["hub", "left", "right", "sink"],
    [("sink", "left"), ("sink", "right"), ("left", "hub"), ("right", "hub")],
    {},
)
assert diamond.prerequisite_closure("sink") == ["hub", "left", "right"]

# cycle must not truncate closure
cycle = mod.KotodamaBench()
cycle.load(
    ["a", "b", "c", "d"],
    [("a", "b"), ("b", "c"), ("c", "a"), ("d", "c")],
    {},
)
assert cycle.prerequisite_closure("d") == ["a", "b", "c"]

print("ok")
