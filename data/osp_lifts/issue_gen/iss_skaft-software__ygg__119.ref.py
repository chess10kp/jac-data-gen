"""Reference harness for skaft-software/ygg#119."""

import importlib.util
from pathlib import Path

_MOD = Path(__file__).with_name("iss_skaft-software__ygg__119.py")
_spec = importlib.util.spec_from_file_location("ygg_119_mod", _MOD)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

load_workflow = _mod.load_workflow
phase_waves = _mod.phase_waves
downstream_phases = _mod.downstream_phases

PHASES = [
    "inspect_plan",
    "investigate_fanout",
    "synthesize",
    "serialized_writer",
    "deterministic_checks",
    "repair_loop",
    "evidence_gate",
]
REQ = [
    ("investigate_fanout", "inspect_plan"),
    ("synthesize", "investigate_fanout"),
    ("serialized_writer", "synthesize"),
    ("deterministic_checks", "serialized_writer"),
    ("repair_loop", "deterministic_checks"),
    ("evidence_gate", "repair_loop"),
]

wf = load_workflow(PHASES, REQ)
assert phase_waves(wf) == [
    ["inspect_plan"],
    ["investigate_fanout"],
    ["synthesize"],
    ["serialized_writer"],
    ["deterministic_checks"],
    ["repair_loop"],
    ["evidence_gate"],
]
assert downstream_phases(wf, "inspect_plan") == [
    "deterministic_checks",
    "evidence_gate",
    "investigate_fanout",
    "repair_loop",
    "serialized_writer",
    "synthesize",
]
assert downstream_phases(wf, "evidence_gate") == []
assert downstream_phases(wf, "missing") == []

cycle = load_workflow(["a", "b", "c"], [("a", "b"), ("b", "c"), ("c", "a")])
assert phase_waves(cycle) is None

diamond = load_workflow(
    ["top", "left", "right", "base", "leaf"],
    [
        ("top", "right"),
        ("base", "leaf"),
        ("left", "base"),
        ("top", "left"),
        ("right", "base"),
    ],
)
assert downstream_phases(diamond, "leaf") == ["base", "left", "right", "top"]

print("ygg 119 ref OK")
