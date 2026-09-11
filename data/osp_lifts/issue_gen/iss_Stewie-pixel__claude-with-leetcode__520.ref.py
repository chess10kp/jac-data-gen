import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_stewie_520",
    Path(__file__).with_name("iss_Stewie-pixel__claude-with-leetcode__520.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

assert mod.remaining_methods(3, 1, [[1, 2]]) == [0]
assert mod.remaining_methods(4, 0, [[0, 1], [0, 2], [0, 3]]) == []
assert mod.remaining_methods(
    5,
    1,
    [[0, 1], [1, 2], [2, 3], [3, 4], [4, 2]],
) == [0, 1, 2, 3, 4]
assert mod.remaining_methods(4, 0, [[0, 1], [1, 2], [2, 3]]) == []
print("ok")
