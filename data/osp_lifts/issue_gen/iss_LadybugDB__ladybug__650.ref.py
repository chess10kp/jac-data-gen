import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_ladybug_650",
    Path(__file__).with_name("iss_LadybugDB__ladybug__650.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

STORE = mod.load_segments(
    ["root", "a", "b", "c"],
    [("root", "a"), ("root", "b"), ("a", "c")],
    [("root", 100), ("a", 80), ("b", 90), ("c", 120)],
)
assert mod.segment_closure(STORE, "root") == ["a", "b", "c", "root"]
assert mod.oversized_segments(STORE, 95) == ["c", "root"]
assert mod.split_candidates(STORE, "root") == ["c"]

assert mod.segment_closure(STORE, "missing") == []
print("ok")
