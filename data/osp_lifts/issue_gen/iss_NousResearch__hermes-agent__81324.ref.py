import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_hermes_81324",
    Path(__file__).with_name("iss_NousResearch__hermes-agent__81324.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_gate_graph(
    ["ab1", "plan_approval", "activation_gate", "implement"],
    [("ab1", "plan_approval"), ("plan_approval", "activation_gate"), ("activation_gate", "implement")],
    {"ab1": "passed", "plan_approval": "passed"},
)
assert mod.ready_gates(g) == ["activation_gate"]
assert mod.activation_path_depth(g, "implement") == 3
assert mod.detect_gate_cycles(g) == []
print("ok")
