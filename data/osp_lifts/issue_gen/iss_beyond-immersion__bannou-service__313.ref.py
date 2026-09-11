"""Reference harness: exercises every public function of iss_beyond-immersion__bannou-service__313."""
import importlib

mod = importlib.import_module("iss_beyond-immersion__bannou-service__313")
ancestors_of = mod.ancestors_of
descendants_of = mod.descendants_of
find_encounters = mod.find_encounters

# Hierarchy rows deliberately child-before-parent: loaders must not need
# top-down row order.
LOCS = [
    {"id": "cellar", "parent_id": "tavern"},
    {"id": "tavern", "parent_id": "old-town"},
    {"id": "downtown", "parent_id": "city"},
    {"id": "old-town", "parent_id": "city"},
    {"id": "city", "parent_id": "realm"},
    {"id": "realm", "parent_id": None},
]
ENCS = [
    {"id": "e-realm", "location_id": "realm"},
    {"id": "e-city", "location_id": "city"},
    {"id": "e-downtown", "location_id": "downtown"},
    {"id": "e-old-town", "location_id": "old-town"},
    {"id": "e-tavern", "location_id": "tavern"},
    {"id": "e-cellar", "location_id": "cellar"},
    {"id": "e-void", "location_id": "void"},
]

assert ancestors_of(LOCS, "cellar") == ["city", "old-town", "realm", "tavern"]
assert ancestors_of(LOCS, "city") == ["realm"]
assert ancestors_of(LOCS, "realm") == []
assert ancestors_of(LOCS, "ghost") == []

assert descendants_of(LOCS, "realm") == ["cellar", "city", "downtown", "old-town", "tavern"]
assert descendants_of(LOCS, "city") == ["cellar", "downtown", "old-town", "tavern"]
assert descendants_of(LOCS, "old-town") == ["cellar", "tavern"]
assert descendants_of(LOCS, "downtown") == []
assert descendants_of(LOCS, "ghost") == []

# Mid-hierarchy query: exact + ancestors + descendants.
assert find_encounters(LOCS, ENCS, "tavern") == [
    "e-cellar", "e-city", "e-old-town", "e-realm", "e-tavern",
]
# City query covers everything except the encounter at unknown "void".
assert find_encounters(LOCS, ENCS, "city") == [
    "e-cellar", "e-city", "e-downtown", "e-old-town", "e-realm", "e-tavern",
]
# Leaf query: exact + the ancestor chain only.
assert find_encounters(LOCS, ENCS, "cellar") == [
    "e-cellar", "e-city", "e-old-town", "e-realm", "e-tavern",
]
# Root query: exact + every descendant.
assert find_encounters(LOCS, ENCS, "realm") == [
    "e-cellar", "e-city", "e-downtown", "e-old-town", "e-realm", "e-tavern",
]
# Exact hit on a location that has no row.
assert find_encounters(LOCS, ENCS, "void") == ["e-void"]
# Unknown location with no encounters anywhere near.
assert find_encounters(LOCS, ENCS, "ghost") == []

# Dangling parent id: counts as an ancestor, then the chain stops.
LOCS2 = [{"id": "a", "parent_id": "missing"}]
ENCS2 = [{"id": "e-m", "location_id": "missing"}, {"id": "e-a", "location_id": "a"}]
assert ancestors_of(LOCS2, "a") == ["missing"]
assert descendants_of(LOCS2, "missing") == ["a"]
assert find_encounters(LOCS2, ENCS2, "a") == ["e-a", "e-m"]

print("iss_beyond-immersion__bannou-service__313 ref OK")
