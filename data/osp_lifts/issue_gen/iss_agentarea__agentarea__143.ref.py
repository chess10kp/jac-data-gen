import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_agentarea__agentarea__143",
    Path(__file__).with_name("iss_agentarea__agentarea__143.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

AGENTS = [
    "director", "mgr", "peer_lead", "lead", "worker_a", "worker_b", "outsider",
]
DELEGATES = [
    ("director", "mgr"),
    ("director", "peer_lead"),
    ("mgr", "lead"),
    ("lead", "worker_a"),
    ("lead", "worker_b"),
    ("peer_lead", "outsider"),
]
REFS = [
    ("mgr", "peer_lead"),
    ("worker_a", "worker_b"),
]

rt = mod.build_runtime(AGENTS, DELEGATES, REFS)
assert mod.delegated_subtree(rt, "mgr") == ["lead", "mgr", "worker_a", "worker_b"]
assert mod.delegated_subtree(rt, "missing") == []

assert mod.cascade_pause(rt, "mgr") == ["lead", "mgr", "worker_a", "worker_b"]
assert mod.agent_state(rt, "worker_a") == "paused"
assert mod.cascade_resume(rt, "lead") == []
assert mod.cascade_resume(rt, "mgr") == ["lead", "mgr", "worker_a", "worker_b"]
assert mod.agent_state(rt, "worker_a") == "running"

assert mod.cascade_cancel(rt, "lead") == ["lead", "worker_a", "worker_b"]
assert mod.agent_state(rt, "worker_a") == "cancelled"
assert mod.cascade_pause(rt, "lead") == []

assert mod.ref_violations(rt, "mgr") == ["mgr->peer_lead"]
assert mod.ref_violations(rt, "director") == ["mgr->peer_lead"]
assert mod.ref_violations(rt, "missing") == []

rt2 = mod.build_runtime(
    ["hub", "left", "right", "sink"],
    [("hub", "left"), ("hub", "right"), ("left", "sink"), ("right", "sink")],
    [],
)
assert mod.delegated_subtree(rt2, "hub") == ["hub", "left", "right", "sink"]

rt3 = mod.build_runtime(
    ["a", "b", "c", "d"],
    [("a", "b"), ("b", "c"), ("c", "a"), ("c", "d")],
    [],
)
assert mod.delegated_subtree(rt3, "a") == ["a", "b", "c", "d"]

print("ok")
