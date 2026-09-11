"""Reference harness: exercises every public function of iss_sora-kisaragi__ai-open-textbook__74."""
import importlib.util
import pathlib

_mod_path = pathlib.Path(__file__).parent / "iss_sora-kisaragi__ai-open-textbook__74.py"
_spec = importlib.util.spec_from_file_location("curriculum_mod", _mod_path)
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
build_curriculum = _mod.build_curriculum
has_cycle = _mod.has_cycle
missing_prereqs = _mod.missing_prereqs
unpositioned_lessons = _mod.unpositioned_lessons
prerequisites_of = _mod.prerequisites_of
unit_totals = _mod.unit_totals

# Information I remediation route: units A-D with cross-unit prerequisites.
LESSONS = [
    ("A1", "A", 2), ("A7", "A", 3),
    ("B1", "B", 3), ("B7", "B", 4),
    ("C1", "C", 5), ("C9", "C", 6),
    ("D1", "D", 7), ("D9", "D", 8),
]
PREREQS = [
    ("B1", "A1"), ("C1", "B1"), ("D1", "C1"),
    ("A7", "A1"), ("B7", "B1"), ("C9", "C1"), ("D9", "D1"),
]

cur = build_curriculum(LESSONS, PREREQS)
assert not has_cycle(cur)
assert missing_prereqs(cur) == []
assert unpositioned_lessons(cur) == []

assert prerequisites_of(cur, "D1") == ["A1", "B1", "C1"]
assert prerequisites_of(cur, "A1") == []
assert prerequisites_of(cur, "ghost") == []

assert unit_totals(cur) == [("A", 5), ("B", 7), ("C", 11), ("D", 15)]

# Validation catches broken data.
broken = build_curriculum(LESSONS, [("B1", "Z9")])
assert missing_prereqs(broken) == [("B1", "Z9")]
zeroed = build_curriculum([("A1", "A", 0)], [])
assert unpositioned_lessons(zeroed) == ["A1"]

# Cycle: C1 needs D1, D1 needs C1.
cyc = build_curriculum(
    [("C1", "C", 5), ("D1", "D", 7), ("X1", "X", 1)],
    [("C1", "D1"), ("D1", "C1")],
)
assert has_cycle(cyc)
# Traversals still terminate under cycles.
assert prerequisites_of(cyc, "C1") == ["D1"]

print("ai-open-textbook 74 ref OK")
