import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_EffortlessMetrics__perl-lsp-swarm__10074",
    Path(__file__).with_name("iss_EffortlessMetrics__perl-lsp-swarm__10074.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

FIXTURE = {
    "prog": {
        "kind": "Block",
        "start": 0,
        "end": 20,
        "refs": [("body", "stmt_a"), ("tail", "stmt_b")],
    },
    "stmt_a": {"kind": "Stmt", "start": 0, "end": 8, "refs": []},
    "stmt_b": {"kind": "Stmt", "start": 9, "end": 20, "refs": []},
}

g = mod.load_snapshot(FIXTURE, "prog", "native-proj-v1", max_nodes=16)
assert mod.field_reachable(g, "prog") == ["stmt_a", "stmt_b"]
assert mod.field_reachable(g, "missing") == []

art, status = mod.build_native_artifact(g)
assert status == "complete"
assert art is not None
assert art["root"] == 0
assert art["nodes"][0]["kind"] == "Block"
assert art["nodes"][0]["fields"] == [("body", 1), ("tail", 2)]

# Adversarial diamond: shared cap reached from two branches
diamond = {
    "hub": {
        "kind": "Block",
        "start": 0,
        "end": 30,
        "refs": [("left", "left"), ("right", "right")],
    },
    "left": {"kind": "Stmt", "start": 0, "end": 10, "refs": [("to", "cap")]},
    "right": {"kind": "Stmt", "start": 11, "end": 20, "refs": [("to", "cap")]},
    "cap": {"kind": "Stmt", "start": 21, "end": 30, "refs": []},
}
g2 = mod.load_snapshot(diamond, "hub", "native-proj-v1")
assert mod.field_reachable(g2, "hub") == ["cap", "left", "right"]

# Ref cycle terminates once
cycle = {
    "a": {"kind": "Loop", "start": 0, "end": 10, "refs": [("body", "b")]},
    "b": {"kind": "Loop", "start": 1, "end": 9, "refs": [("next", "a")]},
}
g3 = mod.load_snapshot(cycle, "a", "native-proj-v1")
assert mod.field_reachable(g3, "a") == ["b"]

# Projection limit
tiny = mod.load_snapshot(FIXTURE, "prog", "native-proj-v1", max_nodes=2)
art2, status2 = mod.build_native_artifact(tiny)
assert art2 is None and status2 == "projection_limit_exceeded"

print("ok")
