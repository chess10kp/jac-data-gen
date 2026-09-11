"""Reference harness for iss_mtetno__devtools__6."""

import importlib.util
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "devtools6",
    HERE / "iss_mtetno__devtools__6.py",
)
mod = importlib.util.module_from_spec(spec)
spec.loader.exec_module(mod)

load_tree = mod.load_tree
descendant_ids = mod.descendant_ids
recursive_sum = mod.recursive_sum

CHAIN = load_tree(
    [("root", 10), ("a", 20), ("b", 30), ("c", 40)],
    [("a", "root"), ("b", "a"), ("c", "b")],
)
assert descendant_ids(CHAIN, "root") == ["a", "b", "c"]
assert recursive_sum(CHAIN, "root") == 100
assert recursive_sum(CHAIN, "b") == 70

BREADTH = load_tree(
    [
        ("root", 1),
        ("w1", 2),
        ("w2", 3),
        ("w3", 4),
        ("deep", 50),
    ],
    [
        ("w1", "root"),
        ("w2", "root"),
        ("w3", "root"),
        ("deep", "w1"),
    ],
)
assert descendant_ids(BREADTH, "root") == ["deep", "w1", "w2", "w3"]
assert recursive_sum(BREADTH, "root") == 60

CYCLE = load_tree(
    [("a", 1), ("b", 2), ("c", 3)],
    [("b", "a"), ("c", "b"), ("a", "c")],
)
assert descendant_ids(CYCLE, "b") == ["a", "c"]
assert recursive_sum(CYCLE, "b") == 6

assert descendant_ids(CHAIN, "missing") == []
assert recursive_sum(CHAIN, "missing") == 0
