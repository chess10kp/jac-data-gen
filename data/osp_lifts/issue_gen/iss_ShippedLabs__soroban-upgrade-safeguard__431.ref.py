"""Reference harness for iss_ShippedLabs__soroban-upgrade-safeguard__431."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_ShippedLabs__soroban-upgrade-safeguard__431.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
load_spec = _mod.load_spec
extract_udts = _mod.extract_udts
references_type = _mod.references_type
is_type_used_in_functions = _mod.is_type_used_in_functions
is_type_used_in_events = _mod.is_type_used_in_events
detect_cascading_layout_breaks = _mod.detect_cascading_layout_breaks
classify_finding_axes = _mod.classify_finding_axes
spec_ok = load_spec(
    {"Point": [], "Line": ["Point"]},
    {"draw": ["Line"]},
    {"Moved": ["Point"]},
)
assert extract_udts(spec_ok, "Line") == ["Line", "Point"]
assert references_type(spec_ok, "Line", "Point") is True
assert references_type(spec_ok, "Point", "Line") is False
assert is_type_used_in_functions(spec_ok, "Line") is True
assert is_type_used_in_functions(spec_ok, "Point") is True
assert is_type_used_in_events(spec_ok, "Point") is True
assert is_type_used_in_events(spec_ok, "Line") is False
assert detect_cascading_layout_breaks(spec_ok, ["Point"]) == ["Line", "Point"]
assert classify_finding_axes(spec_ok, "Point") == [
    "event_usage",
    "function_usage",
    "layout_cascade",
]

spec_cycle = load_spec(
    {"A": ["B"], "B": ["A"], "C": ["u32"], "S": ["S"]},
    {"f": ["A"]},
    {"E": ["C"]},
)
assert extract_udts(spec_cycle, "A") == ["A", "B"]
assert extract_udts(spec_cycle, "S") == ["S"]
assert references_type(spec_cycle, "A", "B") is True
assert references_type(spec_cycle, "S", "S") is True
assert detect_cascading_layout_breaks(spec_cycle, ["A"]) == ["A", "B"]
assert is_type_used_in_events(spec_cycle, "C") is True
assert references_type(spec_cycle, "A", "C") is False
assert is_type_used_in_functions(spec_cycle, "C") is False
assert classify_finding_axes(spec_cycle, "C") == ["event_usage", "layout_cascade"]

spec_diamond = load_spec(
    {
        "hub": ["right", "left"],
        "left": ["leaf"],
        "right": ["leaf"],
        "leaf": [],
    },
    {},
    {},
)
assert extract_udts(spec_diamond, "hub") == ["hub", "leaf", "left", "right"]

assert extract_udts(spec_ok, "Missing") == ["Missing"]
assert references_type(spec_ok, "Missing", "Point") is False
assert is_type_used_in_functions(spec_ok, "Ghost") is False
assert is_type_used_in_events(spec_ok, "Ghost") is False
assert detect_cascading_layout_breaks(spec_ok, ["Ghost"]) == ["Ghost"]
assert classify_finding_axes(spec_ok, "Ghost") == ["layout_cascade"]
print("iss_ShippedLabs__soroban-upgrade-safeguard__431 ref OK")
print("iss_ShippedLabs__soroban-upgrade-safeguard__431 ref OK")
