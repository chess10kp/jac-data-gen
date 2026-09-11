import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_wb_286",
    Path(__file__).with_name("iss_NewChoBo__workbench-kit__286.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

h = mod.load_harness([
    ("harness", None),
    ("decision_safety", "harness"),
    ("workbench_overlay", "harness"),
    ("canary", "workbench_overlay"),
])
assert mod.governance_chain(h, "canary") == ["harness", "workbench_overlay", "canary"]
assert mod.descendant_resources(h, "harness") == ["canary", "decision_safety", "harness", "workbench_overlay"]
assert not mod.has_cycle(h)
print("ok")
