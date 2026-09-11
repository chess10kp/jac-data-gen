import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod",
    Path(__file__).with_name("iss_gmeligio__gx__124.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

USES = [("scan", "step_a"), ("step_a", "step_b"), ("step_b", "step_c"), ("comp", "inner")]
COMPOSITE = {"comp", "step_a"}

assert mod.follow_local_uses("scan", USES, COMPOSITE) == [
    "scan", "step_a", "step_b", "step_c"
]
assert mod.nested_references("comp", USES, COMPOSITE) == ["inner"]
assert mod.managed_closure(["scan"], USES, COMPOSITE) == [
    "scan", "step_a", "step_b", "step_c"
]
print("ok")
