"""Reference harness: exercises every public function of iss_BootBlock__Gubbins__539."""
import importlib.util
import sys
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "gb539", Path(__file__).parent / "iss_BootBlock__Gubbins__539.py"
)
mod = importlib.util.module_from_spec(spec)
sys.modules["gb539"] = mod
spec.loader.exec_module(mod)

KitStore, ContainmentCycleError = mod.KitStore, mod.ContainmentCycleError

k = KitStore()
for i in ("box", "pouch", "pallet", "screw"):
    k.add_item(i, is_kit=(i != "screw"))
k.add_kit_component("box", "pouch")
k.add_kit_component("pouch", "screw")
k.add_kit_component("box", "pallet")

assert k.direct_components("box") == ["pallet", "pouch"]
assert k.all_components("box") == ["pallet", "pouch", "screw"]
assert k.all_components("screw") == []
assert k.kit_count() == 3

# Pre-write validation: nesting a kit under its own component refused.
try:
    k.add_kit_component("pouch", "box")
    raise AssertionError("expected ContainmentCycleError")
except ContainmentCycleError:
    pass
try:
    k.add_kit_component("pouch", "pouch")
    raise AssertionError("expected self-containment error")
except ContainmentCycleError:
    pass
# Refusals leave the edge table untouched.
assert len(k.contains) == 3

# The merged-graph hazard: an existing two-cycle is detected, not fatal.
m = KitStore()
m.add_item("X", True)
m.add_item("Y", True)
m.add_kit_component("X", "Y")
m.contains.append(("Y", "X"))  # adversarial sync merge bypassing validation
assert m.all_components("X") == ["Y"]      # finite despite the loop
assert m.has_containment_cycle("X")

# Errors.
try:
    k.add_kit_component("ghost", "screw")
    raise AssertionError("expected KeyError")
except KeyError:
    pass
try:
    k.add_kit_component("screw", "pouch")  # screw is not a kit
    raise AssertionError("expected ValueError")
except ValueError:
    pass

print("gubbins 539 ref OK")
