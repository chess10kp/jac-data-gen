"""Reference harness: exercises every public function of rec_20."""
from rec_20_ferry_planner import build_ferryweb, can_travel, island_groups

web = build_ferryweb(
    ["kai", "loa", "miri", "noku", "opa"],
    [("kai", "loa"), ("miri", "noku")],
)

groups = island_groups(web)
assert len(groups) == 3
assert groups[0] == ["kai", "loa"]
assert groups[1] == ["miri", "noku"]
assert groups[2] == ["opa"]

assert can_travel(web, "kai", "loa")
assert not can_travel(web, "kai", "miri")
assert can_travel(web, "noku", "miri")
assert can_travel(web, "opa", "opa")   # same island

# Negative cases.
assert not can_travel(web, "ghost", "kai")
assert not can_travel(web, "kai", "ghost")

# Ring route: cycle-safe flood.
ring = build_ferryweb(["p", "q", "r"], [("p", "q"), ("q", "r"), ("r", "p")])
assert island_groups(ring) == [["p", "q", "r"]]
assert can_travel(ring, "r", "p")

print("rec_20 ref OK")
