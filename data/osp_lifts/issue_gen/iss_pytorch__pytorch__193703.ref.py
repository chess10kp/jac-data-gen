import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_pytorch__pytorch__193703",
    Path(__file__).with_name("iss_pytorch__pytorch__193703.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

CHAIN = mod.load_ir_graph([(0, 1), (1, 2), (2, 3)])
assert mod.access_reach(CHAIN, 0) == [0, 1, 2, 3]
assert mod.param_touch_count(CHAIN, 0, 2) == 1

DIAMOND = mod.load_ir_graph([(0, 1), (0, 2), (1, 3), (2, 3), (3, 4)])
assert mod.access_reach(DIAMOND, 0) == [0, 1, 2, 3, 4]
assert mod.param_touch_count(DIAMOND, 0, 3) == 1

SHARED = mod.load_ir_graph([(0, 1), (1, 2), (1, 3), (2, 4), (3, 4)])
assert mod.access_reach(SHARED, 0) == [0, 1, 2, 3, 4]

CYCLE = mod.load_ir_graph([(0, 1), (1, 2), (2, 0)])
assert mod.access_reach(CYCLE, 0) == [0, 1, 2]

assert mod.access_reach(CHAIN, 99) == []
assert mod.param_touch_count(CHAIN, 99, 0) == 0
print("ok")
