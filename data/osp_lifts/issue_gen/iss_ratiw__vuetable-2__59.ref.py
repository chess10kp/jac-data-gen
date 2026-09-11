"""Reference harness: exercises every public function of iss_ratiw__vuetable-2__59."""
import importlib

mod = importlib.import_module("iss_ratiw__vuetable-2__59")
ancestors_of = mod.ancestors_of
has_callback = mod.has_callback
load_tree = mod.load_tree
resolve_owner = mod.resolve_owner
visible_methods = mod.visible_methods

# The issue's layout: root page owns `test`; column/row are plain scaffolding.
tree = load_tree({
    "page": (None, ["test", "fmt"]),
    "row": ("page", []),
    "column": ("row", []),
    "vuetable": ("column", ["refresh"]),
})

# Immediate parent (the column) does not define `test`; the ascent must
# keep going and find it on the page component.
assert ancestors_of(tree, "vuetable") == ["vuetable", "column", "row", "page"]
assert resolve_owner(tree, "vuetable", "test") == "page"
assert has_callback(tree, "vuetable", "test")

# Self-owned method resolves without ascent.
assert resolve_owner(tree, "vuetable", "refresh") == "vuetable"

# Nearest wins: both page and a mid-chain component define `fmt`.
tree2 = load_tree({
    "root": (None, ["fmt"]),
    "mid": ("root", ["fmt"]),
    "leaf": ("mid", []),
})
assert resolve_owner(tree2, "leaf", "fmt") == "mid"

# No owner anywhere.
assert resolve_owner(tree, "vuetable", "missing") is None
assert not has_callback(tree, "vuetable", "missing")

# Unknown component: empty chain, no owner.
assert ancestors_of(tree, "ghost") == []
assert resolve_owner(tree, "ghost", "test") is None

# Unknown parent terminates the chain at the last known component.
tree3 = load_tree({"a": ("nowhere", ["go"]), "b": ("a", [])})
assert ancestors_of(tree3, "b") == ["b", "a"]
assert resolve_owner(tree3, "b", "go") == "a"

# Visible methods union along the chain.
assert visible_methods(tree, "vuetable") == ["fmt", "refresh", "test"]
assert visible_methods(tree, "row") == ["fmt", "test"]

print("iss_ratiw__vuetable-2__59 ref OK")
