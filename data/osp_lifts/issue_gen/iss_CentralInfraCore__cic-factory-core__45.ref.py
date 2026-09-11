import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_cic_45",
    Path(__file__).with_name("iss_CentralInfraCore__cic-factory-core__45.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

PLAN = mod.load_plan(
    ["fc00", "fc01", "fc04", "fc05", "fc06"],
    [
        ("fc00", "fc05"),
        ("fc01", "fc04"),
        ("fc04", "fc06"),
        ("fc05", "fc06"),
    ],
)
assert mod.blocked_by(PLAN, "fc06") == ["fc00", "fc01", "fc04", "fc05"]
assert mod.ready_tasks(PLAN, ["fc00", "fc01"]) == ["fc04", "fc05"]
assert mod.wave_count(PLAN) == 3

assert mod.blocked_by(PLAN, "missing") == []
print("ok")
