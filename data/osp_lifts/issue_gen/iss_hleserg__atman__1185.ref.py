"""Reference harness: exercises every public function of iss_hleserg__atman__1185."""
from iss_hleserg__atman__1185 import (
    are_related,
    link,
    neighbors,
    new_memory,
    related_within,
    remember,
)

mem = new_memory()
remember(mem, "solo")
link(mem, "ada", "knows", "bob")
link(mem, "ada", "mentions", "ci")
link(mem, "bob", "knows", "dee")

# One-hop queries, with and without kind filter.
assert neighbors(mem, "ada") == ["bob", "ci"]
assert neighbors(mem, "ada", ["knows"]) == ["bob"]
assert neighbors(mem, "ghost") == []
assert neighbors(mem, "solo") == []

# Hop-budgeted reachability: exact set within depth.
assert related_within(mem, "ada", 1) == ["ada", "bob", "ci"]
assert related_within(mem, "ada", 2) == ["ada", "bob", "ci", "dee"]
assert related_within(mem, "ada", 2, ["mentions"]) == ["ada", "ci"]

# Unbounded reachability is directional.
assert are_related(mem, "ada", "dee")
assert not are_related(mem, "dee", "ada")
assert not are_related(mem, "x", "y")
assert not are_related(mem, "solo", "solo")

# Relation cycle terminates without truncation.
cyc = new_memory()
link(cyc, "p", "knows", "q")
link(cyc, "q", "knows", "p")
link(cyc, "q", "knows", "r")
assert related_within(cyc, "p", 7) == ["p", "q", "r"]
assert neighbors(cyc, "p") == ["q"]
assert are_related(cyc, "p", "r")

print("iss_hleserg__atman__1185 ref OK")
