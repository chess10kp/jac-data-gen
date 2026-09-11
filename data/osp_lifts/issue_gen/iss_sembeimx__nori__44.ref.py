"""Reference harness: exercises every public function of iss_sembeimx__nori__44."""
from iss_sembeimx__nori__44 import CycleMove, ancestors, build_tree, depth_of, descendants, move_to

tree = build_tree([1, 2, 3, 4, 5], [(2, 1), (3, 1), (4, 2), (5, 2)])
assert ancestors(tree, 4) == [1, 2]
assert ancestors(tree, 1) == []
assert descendants(tree, 1) == [2, 3, 4, 5]
assert descendants(tree, 2) == [4, 5]
assert depth_of(tree, 4) == 2
assert depth_of(tree, 1) == 0

# move_to refuses self- and descendant-targeting moves.
for bad_target in (4, 5):
    try:
        move_to(tree, 2, bad_target)
        raise AssertionError("expected CycleMove")
    except CycleMove as e:
        assert str(e) == "move forms a parent cycle"
try:
    move_to(tree, 2, 2)
    raise AssertionError("expected CycleMove")
except CycleMove:
    pass
# rejected moves changed nothing
assert descendants(tree, 2) == [4, 5]

# A legal move keeps every view consistent.
move_to(tree, 4, 3)
assert ancestors(tree, 4) == [1, 3]
assert descendants(tree, 2) == [5]
assert depth_of(tree, 4) == 2

# Rooting a subtree.
move_to(tree, 5, None)
assert ancestors(tree, 5) == []

# Corrupt parent cycle: walks terminate (defense in depth).
corrupt = build_tree([7, 8], [(7, 8), (8, 7)])
assert ancestors(corrupt, 7) == [8]
assert depth_of(corrupt, 7) == 1
assert sorted(descendants(corrupt, 7)) == [8]

print("iss_sembeimx__nori__44 ref OK")
