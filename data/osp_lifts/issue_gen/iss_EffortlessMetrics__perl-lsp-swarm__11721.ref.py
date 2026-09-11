"""Reference harness for EffortlessMetrics/perl-lsp-swarm#11721."""

import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_EffortlessMetrics__perl-lsp-swarm__11721",
    Path(__file__).with_suffix(".py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

load_pipeline = mod.load_pipeline
stage_order = mod.stage_order
owners_for = mod.owners_for

STAGES = [
    ("schema", "arch"),
    ("ledger", "arch"),
    ("collision", "ci"),
    ("render", "docs"),
]
DEPS = [
    ("ledger", "schema"),
    ("collision", "schema"),
    ("render", "ledger"),
    ("render", "collision"),
]

g = load_pipeline(STAGES, DEPS)
assert stage_order(g) == [["schema"], ["collision", "ledger"], ["render"]]
assert owners_for(g, "render") == ["arch", "ci", "docs"]

cyc = load_pipeline([("a", "x"), ("b", "y")], [("a", "b"), ("b", "a")])
assert stage_order(cyc) is None

diamond = load_pipeline(
    [("root", "arch"), ("left", "lsp"), ("right", "dap"), ("sink", "gate")],
    [("sink", "left"), ("sink", "right"), ("left", "root"), ("right", "root")],
)
assert owners_for(diamond, "sink") == ["arch", "dap", "gate", "lsp"]
assert owners_for(g, "missing") == []

print("ok")
