"""Reference harness: exercises every public function of iss_kitelev__exocortex__4196."""
import importlib

mod = importlib.import_module("iss_kitelev__exocortex__4196")
ZoneTree = mod.ZoneTree

zt = ZoneTree()
zt.add_zone("TBank")
zt.add_zone("Sales Offering", "TBank")
zt.add_zone("Operations", "TBank")
zt.add_zone("TOOS Group", "Sales Offering")
zt.add_zone("People Management", "TOOS Group")
zt.add_zone("Value Delivery", "TOOS Group")

zt.assign("People Management", 17)
zt.assign("Value Delivery", 5)
zt.assign("Operations", 11)
zt.assign("TBank", 3)

# Subtree rollup matches the issue's expected table shape.
assert zt.aggregate("TOOS Group") == 22
assert zt.aggregate("Sales Offering") == 22
assert zt.aggregate("TBank") == 36
assert zt.aggregate("Operations") == 11
assert zt.direct_capacity("TBank") == 3
assert zt.direct_capacity("TOOS Group") == 0

# Ancestors: nearest first, excluding self.
assert zt.ancestors("People Management") == ["TOOS Group", "Sales Offering", "TBank"]
assert zt.ancestors("TBank") == []

# Descendants: full closure vs exact-level filter.
assert zt.descendants("TBank") == ["Operations", "People Management",
                                   "Sales Offering", "TOOS Group", "Value Delivery"]
assert zt.descendants("TBank", depth=1) == ["Operations", "Sales Offering"]
assert zt.descendants("TBank", depth=2) == ["TOOS Group"]
assert zt.descendants("TOOS Group") == ["People Management", "Value Delivery"]
assert zt.descendants("Value Delivery") == []

# Unknown ids raise exactly like the source.
for fn in (zt.aggregate, zt.ancestors, zt.descendants, zt.direct_capacity):
    try:
        fn("ghost")
        raise SystemExit("expected KeyError")
    except KeyError:
        pass
try:
    zt.assign("ghost")
    raise SystemExit("expected KeyError on assign")
except KeyError:
    pass
try:
    zt.add_zone("x", "ghost")
    raise SystemExit("expected KeyError on add")
except KeyError:
    pass

# Cycle tolerance: corrupt the parent links (A <-> B) and re-read.
zt2 = ZoneTree()
zt2.add_zone("A")
zt2.add_zone("B", "A")
zt2.assign("A", 4)
zt2.assign("B", 6)
zt2.parent_of["A"] = "B"          # forge a two-cycle, bypassing the API
zt2.children["B"].append("A")
assert zt2.aggregate("A") == 10   # no hang, no double count
assert zt2.ancestors("A") == ["B"]
assert sorted(zt2.descendants("A")) == ["B"]

# Diamond: shared leaf counted once in aggregate and once in descendants.
zt3 = ZoneTree()
zt3.add_zone("top")
zt3.add_zone("l", "top")
zt3.add_zone("r", "top")
zt3.add_zone("bot", "l")
zt3.children["r"].append("bot")   # second path to bot
zt3.parent_of["bot"] = "l"
zt3.assign("bot", 7)
zt3.assign("top", 1)
assert zt3.aggregate("top") == 8
assert zt3.descendants("top") == ["bot", "l", "r"]
