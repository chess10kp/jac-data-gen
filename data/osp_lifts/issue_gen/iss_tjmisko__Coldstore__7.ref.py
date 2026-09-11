"""Reference harness for tjmisko/Coldstore#7."""

import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_tjmisko__Coldstore__7",
    Path(__file__).with_suffix(".py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

load_tags = mod.load_tags
descendant_tags = mod.descendant_tags
delete_tag = mod.delete_tag
merge_tags = mod.merge_tags

# load_tags materializes ancestor rows
c = load_tags(["Trips/Iceland/Reykjavik", "Trips/Norway/Oslo", "Books/Fiction"])
assert descendant_tags(c, "Trips") == [
    "Trips/Iceland",
    "Trips/Iceland/Reykjavik",
    "Trips/Norway",
    "Trips/Norway/Oslo",
]
assert descendant_tags(c, "Books") == ["Books/Fiction"]
assert descendant_tags(c, "missing") == []

# delete_tag — leaf
c = load_tags(["A/B", "A/C"])
assert delete_tag(c, "A/B") == ["A/B"]
assert descendant_tags(c, "A") == ["A/C"]

# delete_tag — blocked without cascade
c = load_tags(["A/B/C"])
try:
    delete_tag(c, "A")
    raise AssertionError("expected ValueError")
except ValueError as e:
    assert str(e) == "has_descendants"

# delete_tag — cascade subtree
c = load_tags(["A/B/C", "A/D"])
assert delete_tag(c, "A", cascade=True) == ["A", "A/B", "A/B/C", "A/D"]
assert descendant_tags(c, "A") == []

# delete_tag — unknown tolerant
c = load_tags(["X"])
assert delete_tag(c, "nope") == []

# merge_tags — reparent direct children, drop src
c = load_tags(["A/B", "C/D"])
assert merge_tags(c, "A", "C") is True
assert descendant_tags(c, "C") == ["A/B", "C/D"]
assert merge_tags(c, "A", "C") is False

print("ok")
