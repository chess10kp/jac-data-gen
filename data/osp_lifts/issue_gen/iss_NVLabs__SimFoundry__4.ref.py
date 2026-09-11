"""Reference harness: exercises every public function of iss_NVLabs__SimFoundry__4."""
from iss_NVLabs__SimFoundry__4 import fallout_of, is_supported_by, load_scene, supporters_of

scene = load_scene(
    ["table", "monitor", "stand", "desk"],
    [("table", "desk"), ("monitor", "table"), ("stand", "table")],
)
assert fallout_of(scene, "desk") == ["desk", "monitor", "stand", "table"]
assert supporters_of(scene, "monitor") == ["desk", "monitor", "table"]
assert is_supported_by(scene, "monitor", "desk")
assert not is_supported_by(scene, "desk", "monitor")

# Diamond: monitor and stand both rest on the table; shared supporter once.
dia = load_scene(
    ["ground", "leg_a", "leg_b", "top"],
    [("leg_a", "ground"), ("leg_b", "ground"), ("top", "leg_a"), ("top", "leg_b")],
)
assert supporters_of(dia, "top") == ["ground", "leg_a", "leg_b", "top"]

# Mutual-support cycle from ambiguous masks: must terminate, multiset intact.
cyc = load_scene(["a", "b", "c"], [("a", "b"), ("b", "a"), ("c", "a")])
assert fallout_of(cyc, "a") == ["a", "b", "c"]
assert supporters_of(cyc, "c") == ["a", "b", "c"]
assert is_supported_by(cyc, "b", "a")

# Self-support and unknown ids follow the source conventions.
solo = load_scene(["x"], [("x", "x")])
assert fallout_of(solo, "x") == ["x"]
empty = load_scene([], [])
assert fallout_of(empty, "ghost") == ["ghost"]
assert supporters_of(empty, "ghost") == ["ghost"]

print("iss_NVLabs__SimFoundry__4 ref OK")
