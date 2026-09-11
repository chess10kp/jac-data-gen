import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod",
    Path(__file__).with_name("iss_Aakif-Kohari__CogniPipe__95.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

store = mod.load_steps([("a", ["b"]), ("b", ["a"])])
cycles = mod.detect_cycles(store)
assert len(cycles) == 1
assert "a" in cycles[0] and "b" in cycles[0]

store2 = mod.load_steps([("a", []), ("b", ["a"]), ("c", ["b"])])
assert mod.detect_cycles(store2) == []

store3 = mod.load_steps([("x", ["y"]), ("y", ["z"]), ("z", ["x"])])
assert len(mod.detect_cycles(store3)) == 1
print("ok")
