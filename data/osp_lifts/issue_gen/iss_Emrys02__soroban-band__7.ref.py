"""Reference harness for iss_Emrys02__soroban-band__7."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_Emrys02__soroban-band__7.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

g = _mod.load_contracts(["A", "B", "C", "D"], [("A", "B"), ("B", "C"), ("A", "D")])
assert _mod.detect_cycles(g) == []
assert _mod.build_order(g) == ["A", "B", "C", "D"]
cyc = _mod.load_contracts(["X", "Y"], [("X", "Y"), ("Y", "X")])
assert _mod.detect_cycles(cyc) == [("Y", "X")]
assert _mod.cycle_members(cyc, "X") == ["X", "Y"]
assert _mod.build_order(cyc) == []

print("iss_Emrys02__soroban-band__7 ref OK")
