"""Reference harness for iss_Dhruv2mars__typescript-relunar-testbed__1143."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_Dhruv2mars__typescript-relunar-testbed__1143.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
CIRC = _mod.load_inference_graph(
    ["circular", "tryAgain", "number"],
    [("tryAgain", "tryAgain"), ("tryAgain", "number")],
    [("circular", "tryAgain")],
    {"circular": "Callable[[], number]", "tryAgain": "number"},
)
assert _mod.returned_closure(CIRC, "circular") == "tryAgain"
assert _mod.has_inference_cycle(CIRC, "tryAgain") is True
assert _mod.effective_return_type(CIRC, "tryAgain") == "number"
assert _mod.effective_return_type(CIRC, "circular") == "Callable[[], number]"
assert _mod.reference_closure(CIRC, "tryAgain") == ["number", "tryAgain"]
assert _mod.reference_closure(CIRC, "circular") == [
    "circular",
    "number",
    "tryAgain",
]

CHAIN = _mod.load_inference_graph(
    ["outer", "inner", "int"],
    [("inner", "int")],
    [("outer", "inner")],
    {"inner": "int", "outer": "Callable[[], int]"},
)
assert _mod.has_inference_cycle(CHAIN, "inner") is False
assert _mod.effective_return_type(CHAIN, "inner") == "int"
assert _mod.reference_closure(CHAIN, "outer") == ["inner", "int", "outer"]

DIAMOND = _mod.load_inference_graph(
    ["hub", "left", "right", "leaf"],
    [
        ("right", "leaf"),
        ("left", "leaf"),
        ("hub", "right"),
        ("hub", "left"),
    ],
    [],
    {"leaf": "number"},
)
assert _mod.reference_closure(DIAMOND, "hub") == ["hub", "leaf", "left", "right"]
assert _mod.effective_return_type(DIAMOND, "leaf") == "number"

MUTUAL = _mod.load_inference_graph(
    ["alpha", "beta"],
    [("alpha", "beta"), ("beta", "alpha")],
    [],
    {},
)
assert _mod.has_inference_cycle(MUTUAL, "alpha") is True
assert _mod.effective_return_type(MUTUAL, "alpha") is None
assert _mod.reference_closure(MUTUAL, "alpha") == ["alpha", "beta"]

assert _mod.returned_closure(CIRC, "missing") is None
assert _mod.reference_closure(CIRC, "missing") == []
assert _mod.has_inference_cycle(CIRC, "missing") is False
assert _mod.effective_return_type(CIRC, "missing") is None
print("iss_Dhruv2mars__typescript-relunar-testbed__1143 ref OK")
