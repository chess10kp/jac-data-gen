import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "iss_runtorque__torque__1407",
    Path(__file__).with_name("iss_runtorque__torque__1407.py"),
)
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

# TORQUE:1588-shaped fixture: merged root, done review, open engineer-message sibling.
g1588 = mod.load_board(
    [
        ("root", "In Progress", ["torque:legacy-root"]),
        ("review", "Done", ["torque:ship-review"]),
        ("msg", "Backlog", ["torque:derived", "torque:engineer-message"]),
    ],
    [("root", "review"), ("root", "msg")],
)
assert mod.task_open_descendants(g1588, "root") == ["msg"]
assert mod.task_has_unresolved_descendants(g1588, "root") is True
assert mod.task_is_engineer_message_followup(g1588, "msg") is True
assert mod.task_has_unresolved_completion_blockers(g1588, "root") is False

# TORQUE:1587 control: no open descendants.
g1587 = mod.load_board(
    [("root", "In Progress", []), ("review", "Done", [])],
    [("root", "review")],
)
assert mod.task_open_descendants(g1587, "root") == []
assert mod.task_has_unresolved_descendants(g1587, "root") is False
assert mod.task_has_unresolved_completion_blockers(g1587, "root") is False

# Real queued work still blocks completion.
g_block = mod.load_board(
    [("root", "In Progress", []), ("work", "Backlog", ["torque:human"])],
    [("root", "work")],
)
assert mod.task_has_unresolved_descendants(g_block, "root") is True
assert mod.task_has_unresolved_completion_blockers(g_block, "root") is True

# Diamond: adversarial edge order forces revisit before deep first-visit.
g_diamond = mod.load_board(
    [
        ("hub", "Done", []),
        ("left", "Done", []),
        ("right", "Done", []),
        ("leaf", "Backlog", []),
    ],
    [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
)
assert mod.task_open_descendants(g_diamond, "hub") == ["leaf"]

# Cycle terminates once per task.
g_cycle = mod.load_board(
    [("a", "Done", []), ("b", "Done", []), ("c", "Backlog", [])],
    [("a", "b"), ("b", "c"), ("c", "a")],
)
assert mod.task_open_descendants(g_cycle, "a") == ["c"]

# Unknown id tolerance.
g_empty = mod.load_board([("solo", "Done", [])], [])
assert mod.task_open_descendants(g_empty, "missing") == []
assert mod.task_has_unresolved_descendants(g_empty, "missing") is False
assert mod.task_has_unresolved_completion_blockers(g_empty, "missing") is False
assert mod.task_is_engineer_message_followup(g_empty, "missing") is False
print("ok")
