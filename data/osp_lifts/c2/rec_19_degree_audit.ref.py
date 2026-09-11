"""Reference harness: exercises every public function of rec_19."""
from rec_19_degree_audit import build_catalog, direct_unlocks, unlocked_by

cat = build_catalog(
    ["CS101", "CS102", "CS201", "MA101", "CS301", "ART100"],
    [
        ("CS101", "CS102"),
        ("CS102", "CS201"),
        ("CS201", "CS301"),
        ("MA101", "CS201"),
    ],
)

assert unlocked_by(cat, ["CS101"]) == ["CS102", "CS201", "CS301"]
assert unlocked_by(cat, ["MA101"]) == ["CS201", "CS301"]
# Multi-source union: both chains merge at CS201.
assert unlocked_by(cat, ["CS101", "MA101"]) == ["CS102", "CS201", "CS301"]
# Done courses themselves are never in the answer.
assert unlocked_by(cat, ["CS101", "CS102"]) == ["CS201", "CS301"]
# Unknown codes ignored.
assert unlocked_by(cat, ["CS101", "GHOST"]) == ["CS102", "CS201", "CS301"]
assert unlocked_by(cat, []) == []

assert direct_unlocks(cat, "CS101") == ["CS102"]
assert direct_unlocks(cat, "CS301") == []
assert direct_unlocks(cat, "NOPE") == []

print("rec_19 ref OK")
