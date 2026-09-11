"""Reference harness for iss_Growth-Circle__cadis__259."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_Growth-Circle__cadis__259.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

idx = _mod.load_dir_index(
    ["ws", "src", "lib", "tests"],
    [("ws", "src"), ("ws", "tests"), ("src", "lib")],
)
assert _mod.indexed_paths(idx, "ws") == ["lib", "src", "tests", "ws"]
assert _mod.walk_terminates(idx, "ws") is True
assert _mod.cycle_detected(idx, "ws") is False
loop = _mod.load_dir_index(["a", "b"], [], symlinks=[("a", "b"), ("b", "a")])
assert _mod.cycle_detected(loop, "a") is True

print("iss_Growth-Circle__cadis__259 ref OK")
