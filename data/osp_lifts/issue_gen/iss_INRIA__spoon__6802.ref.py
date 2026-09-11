import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_INRIA__spoon__6802",
    Path(__file__).with_name("iss_INRIA__spoon__6802.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

CHAIN = mod.load_type_graph(
    ["wildcard", "bound_E", "E"],
    [("wildcard", "bound_E"), ("bound_E", "E")],
    [("E", "Object"), ("bound_E", "Object")],
)
assert mod.erasure_chain(CHAIN, "wildcard") == ["wildcard", "bound_E", "E"]
assert mod.erasure_of(CHAIN, "wildcard") == "Object"

CYCLE = mod.load_type_graph(
    ["w", "b", "c"],
    [("w", "b"), ("b", "c"), ("c", "w")],
    [("w", "Object")],
)
assert mod.erasure_chain(CYCLE, "w") == ["w", "b", "c"]
assert mod.erasure_of(CYCLE, "w") == "Object"

LOWER = mod.load_type_graph(
    ["lower", "object_bound"],
    [("lower", "object_bound")],
    [("object_bound", "Object")],
)
assert mod.erasure_of(LOWER, "lower") == "Object"

assert mod.erasure_chain(CHAIN, "missing") == []
assert mod.erasure_of(CHAIN, "missing") == "Object"
print("ok")
