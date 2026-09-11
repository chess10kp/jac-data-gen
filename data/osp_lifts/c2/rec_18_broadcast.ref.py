"""Reference harness: exercises every public function of rec_18."""
from rec_18_broadcast import build_cluster, broadcast_plan, propagation_time

net = build_cluster(
    ["n1", "n2", "n3", "n4", "n5", "n6"],
    [
        ("n1", "n2"),
        ("n1", "n3"),
        ("n2", "n4"),
        ("n3", "n4"),   # diamond: n4 must pin at 2 either way
        ("n4", "n5"),
        ("n6", "n1"),
    ],
)

plan = broadcast_plan(net, "n1")
assert plan == {"n1": 0, "n2": 1, "n3": 1, "n6": 1, "n4": 2, "n5": 3}
assert propagation_time(net, "n1") == 3

assert broadcast_plan(net, "n5")["n1"] == 3
assert propagation_time(net, "n5") == 4

# Singleton origin.
lone = build_cluster(["only"], [])
assert broadcast_plan(lone, "only") == {"only": 0}
assert propagation_time(lone, "only") == 0

# Unknown origin.
assert broadcast_plan(net, "ghost") == {}
assert propagation_time(net, "ghost") == -1

# Ring: cycle safety with exact levels.
ring = build_cluster(["r1", "r2", "r3"], [("r1", "r2"), ("r2", "r3"), ("r3", "r1")])
assert broadcast_plan(ring, "r2") == {"r1": 1, "r2": 0, "r3": 1}

print("rec_18 ref OK")
