import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_1092",
    Path(__file__).with_name("iss_trueagi-io__hyperon-experimental__1092.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_type_graph(
    ["A", "B", "C", "D"],
    [("A", "B"), ("B", "C"), ("C", "D")],
)
assert mod.collect_supertypes(store, "A", 2) == ["B", "C"]
assert mod.collect_supertypes(store, "A", 10) == ["B", "C", "D"]

store_i = mod.load_type_graph(
    ["M1", "M2"],
    [],
    [("M1", "M2"), ("M2", "M1")],
)
assert mod.detect_mutual_import(store_i, "M1", "M2") is True
print("ok")
