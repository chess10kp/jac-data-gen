"""Reference harness: exercises every public function of rec_11."""
from rec_11_friend_circles import build_network, circle_count, circle_of

net = build_network(
    ["ann", "bee", "cid", "dan", "eve"],
    [("ann", "bee"), ("bee", "cid"), ("dan", "eve")],
)
assert circle_of(net, "ann") == ["ann", "bee", "cid"]
assert circle_of(net, "eve") == ["dan", "eve"]
assert circle_count(net) == 2

# Unknown member -> empty circle (source convention).
assert circle_of(net, "ghost") == []

# Isolated members: each is its own circle.
lone = build_network(["x", "y", "z"], [])
assert circle_count(lone) == 3
assert circle_of(lone, "y") == ["y"]

# Diamond: revisiting `d` via b and c must not duplicate or hang.
dia = build_network(
    ["a", "b", "c", "d"],
    [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d")],
)
assert circle_of(dia, "a") == ["a", "b", "c", "d"]
assert circle_count(dia) == 1

print("rec_11 ref OK")
