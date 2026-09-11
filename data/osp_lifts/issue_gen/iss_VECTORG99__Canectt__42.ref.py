"""Reference harness: exercises every public function of iss_VECTORG99__Canectt__42."""
import importlib

mod = importlib.import_module("iss_VECTORG99__Canectt__42")
load_schedule = mod.load_schedule
nesting_depth = mod.nesting_depth
subtree = mod.subtree
validate = mod.validate


def doc(**over):
    base = {
        "timezone": "America/Santiago",
        "dayRange": ["06:00", "22:00"],
        "recurrence": {"byDay": ["MO", "FR"]},
        "blocks": [
            {"id": "day", "parentId": None, "startTime": "08:00", "endTime": "18:00"},
            {"id": "am", "parentId": "day", "startTime": "08:00", "endTime": "12:00"},
            {"id": "am-early", "parentId": "am", "startTime": "08:00", "endTime": "09:30"},
        ],
    }
    base.update(over)
    return base


# Valid schedule: no errors, nesting queries work.
sched = load_schedule(doc())
assert validate(sched) == []
assert subtree(sched, "am") == ["am", "am-early"]
assert subtree(sched, "day") == ["am", "am-early", "day"]
assert nesting_depth(sched, "day") == 2
assert nesting_depth(sched, "am-early") == 0
assert subtree(sched, "nope") == []
assert nesting_depth(sched, "nope") == -1

# parentId cycle: A -> B -> A must be rejected, cycle named.
cyc = load_schedule(doc(blocks=[
    {"id": "A", "parentId": "B", "startTime": "08:00", "endTime": "09:00"},
    {"id": "B", "parentId": "A", "startTime": "09:00", "endTime": "10:00"},
]))
errs = validate(cyc)
assert errs == ["cycle: A -> B -> A"], errs

# Self-cycle.
selfc = load_schedule(doc(blocks=[
    {"id": "A", "parentId": "A", "startTime": "08:00", "endTime": "09:00"},
]))
assert validate(selfc) == ["cycle: A -> A"]

# Unknown parent reference.
unk = load_schedule(doc(blocks=[
    {"id": "A", "parentId": "ghost", "startTime": "08:00", "endTime": "09:00"},
]))
assert validate(unk) == ["unknown parent: A -> ghost"]

# Block outside dayRange.
out = load_schedule(doc(blocks=[
    {"id": "night", "parentId": None, "startTime": "03:00", "endTime": "05:00"},
]))
assert validate(out) == ["block outside dayRange: night"]

# Duplicate byDay + bad timezone + duplicate ids (sorted output).
multi = load_schedule(doc(
    timezone="Mars/Olympus",
    recurrence={"byDay": ["MO", "MO", "FR"]},
    blocks=[
        {"id": "x", "parentId": None, "startTime": "08:00", "endTime": "09:00"},
        {"id": "x", "parentId": None, "startTime": "10:00", "endTime": "11:00"},
    ],
))
assert validate(multi) == [
    "duplicate byDay: MO",
    "duplicate id: x",
    "invalid timezone: Mars/Olympus",
]

print("iss_VECTORG99__Canectt__42 ref OK")
