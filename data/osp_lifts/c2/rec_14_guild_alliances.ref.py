"""Reference harness: exercises every public function of rec_14."""
from rec_14_guild_alliances import allied_with, allies_of, build_league

net = build_league(
    ["WOLF", "HAWK", "BEAR", "TIDE", "DUNE"],
    [("WOLF", "HAWK"), ("HAWK", "BEAR"), ("TIDE", "DUNE")],
)

assert allies_of(net, "WOLF") == ["BEAR", "HAWK", "WOLF"]
assert allies_of(net, "TIDE") == ["DUNE", "TIDE"]
assert allied_with(net, "WOLF", "BEAR")
assert allied_with(net, "WOLF", "WOLF")   # self is trivially allied
assert not allied_with(net, "WOLF", "TIDE")

# Pact cycle must not hang the flood.
ring = build_league(["A", "B", "C"], [("A", "B"), ("B", "C"), ("C", "A")])
assert allies_of(ring, "B") == ["A", "B", "C"]
assert allied_with(ring, "C", "A")

# Negative cases.
assert allies_of(net, "NOPE") == []
assert not allied_with(net, "WOLF", "NOPE")
assert not allied_with(net, "NOPE", "WOLF")

lone = build_league(["SOLO"], [])
assert allies_of(lone, "SOLO") == ["SOLO"]
assert allied_with(lone, "SOLO", "SOLO")

print("rec_14 ref OK")
