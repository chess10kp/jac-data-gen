import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_numba_9316",
    Path(__file__).with_name("iss_numba__numba__9316.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_cache_graph(
    ["foo", "bar", "baz"],
    ["GLOBAL_VAL1", "GLOBAL_VAL2", "GLOBAL_VAL3"],
    [("foo", "GLOBAL_VAL1"), ("bar", "GLOBAL_VAL2"), ("baz", "GLOBAL_VAL3")],
)
assert mod.invalidated_by_global(g, ["GLOBAL_VAL2"]) == ["bar"]
assert mod.globals_for_func(g, "foo") == ["GLOBAL_VAL1"]
assert mod.would_invalidate(g, "foo", "GLOBAL_VAL2") is False
print("ok")
