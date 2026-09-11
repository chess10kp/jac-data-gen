import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod38",
    Path(__file__).with_name("iss_netkeep80__pjson__38.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_refs(
    [("a", "value_a"), ("b", None), ("c", "value_c"), ("d", "value_d")],
    [("b", "a"), ("c", "b"), ("d", "c")],
)
assert mod.resolve(store, "d", 10) == "value_a"
assert mod.deref_chain(store, "d") == ["d", "c", "b"]
assert mod.resolve(store, "a", 5) == "value_a"

cyclic = mod.load_refs([("x", None), ("y", None), ("z", None)], [("x", "y"), ("y", "z"), ("z", "x")])
assert mod.resolve(cyclic, "x", 10) is None
assert mod.is_cyclic_ref(cyclic, "x") is True
print("ok")
