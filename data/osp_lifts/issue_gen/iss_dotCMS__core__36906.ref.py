"""Reference harness: exercises every public function of iss_dotCMS__core__36906."""
import importlib

mod = importlib.import_module("iss_dotCMS__core__36906")
CategoryTree = mod.CategoryTree

t = CategoryTree()
t.add_category("products", None)
for i, name in enumerate(["hardware", "software"]):
    t.add_category(name, parent="products", order=i)
t.add_category("laptops", parent="hardware", order=0)
t.add_category("gaming", parent="laptops", order=0)      # level 3: the bug zone
t.add_category("rtx", parent="gaming", order=0)          # level 4

# Sibling order is observable.
assert t.children_ordered("products") == ["hardware", "software"]
assert t.children_ordered("hardware") == ["laptops"]

# Cross-listing: one contentlet in many categories, shared across subtrees.
t.attach_content("sku-1", "rtx")
t.attach_content("sku-1", "software")     # cross-listed outside doomed set
t.attach_content("sku-2", "gaming")

# Contents reachable from a subtree.
assert t.contents_in_subtree("gaming") == ["sku-1", "sku-2"]
assert t.contents_in_subtree("software") == ["sku-1"]

# THE FIX: deep delete removes all levels, not just direct children.
total, per_level = t.delete_category_deep("laptops")
assert total == 3                          # laptops, gaming, rtx
assert per_level == [1, 1, 1]
assert sorted(t.parent_of.keys()) == ["hardware", "products", "software"]
assert t.orphaned_categories() == []       # no severed survivors
# Cross-listed contentlet survives with its outside link intact.
assert t.content_of["sku-1"] == {"software"}
assert t.content_of["sku-2"] == set()

# Deleting a leaf is the trivial case.
total, per_level = t.delete_category_deep("hardware")
assert (total, per_level) == (1, [1])

# Level structure of a deeper tree before deletion.
u = CategoryTree()
u.add_category("root", None)
u.add_category("a", "root", 0)
u.add_category("b", "root", 1)
u.add_category("a1", "a", 0)
u.add_category("a2", "a", 1)
u.add_category("a1x", "a1", 0)
levels = u._subtree_levels("root")
assert [len(l) for l in levels] == [1, 2, 2, 1]

total, per_level = u.delete_category_deep("a")
assert (total, per_level) == (4, [1, 2, 1])   # a, a1, a2, a1x
assert u.orphaned_categories() == []
assert u.children_ordered("root") == ["b"]

# Unknown category errors are directed.
try:
    t.delete_category_deep("ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    pass
try:
    t.attach_content("sku-9", "ghost")
    raise SystemExit("expected KeyError")
except KeyError:
    pass
