import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_dotnaos_879",
    Path(__file__).with_name("iss_DotNaos__project-space__879.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

TREE = mod.load_change_tree(
    ["feat", "backend", "frontend", "auth", "ui"],
    [("feat", "backend"), ("feat", "frontend"), ("backend", "auth"), ("frontend", "ui")],
    [
        ("feat", "accepted"),
        ("backend", "accepted"),
        ("frontend", "deferred"),
        ("auth", "rejected"),
        ("ui", "deferred"),
    ],
)
assert mod.descendant_pieces(TREE, "feat") == ["auth", "backend", "frontend", "ui"]
assert mod.flatten_leaves(TREE, "feat") == ["auth", "ui"]
assert mod.partition_accounting(TREE) == {"accepted": 2, "rejected": 1, "deferred": 2}
assert mod.review_complete(TREE) is False

assert mod.descendant_pieces(TREE, "missing") == []
print("ok")
