import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("mod", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

c = mod.load_cartography(
    ["raw", "parsed", "validated", "contract", "persisted"],
    [
        ("parsed", "raw"),
        ("validated", "parsed"),
        ("contract", "validated"),
        ("persisted", "contract"),
    ],
)
assert mod.lineage_closure(c, "persisted") == [
    "contract",
    "parsed",
    "raw",
    "validated",
]
assert mod.canonical_fields(c) == [
    "raw",
    "parsed",
    "validated",
    "contract",
    "persisted",
]

diamond = mod.load_cartography(
    ["top", "left", "right", "base", "leaf"],
    [
        ("top", "right"),
        ("base", "leaf"),
        ("left", "base"),
        ("top", "left"),
        ("right", "base"),
    ],
)
assert mod.lineage_closure(diamond, "top") == ["base", "leaf", "left", "right"]

cyc = mod.load_cartography(
    ["a", "b", "c"],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert mod.canonical_fields(cyc) is None
assert mod.lineage_closure(c, "missing") == []
print("ok")
