import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "mod",
    Path(__file__).with_name("iss_aetorresdev__ai-minions__341.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

g = mod.load_exec_graph(["a", "b"], [("a", "b"), ("b", "a")])
assert not mod.valid_exec_graph(g)
assert len(mod.detect_exec_cycles(g)) >= 1

g2 = mod.load_exec_graph(["a", "b", "c"], [("a", "b"), ("b", "c")])
assert mod.valid_exec_graph(g2)
print("ok")
