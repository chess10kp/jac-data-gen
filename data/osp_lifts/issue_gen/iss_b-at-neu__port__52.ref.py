"""Reference harness for iss_b-at-neu__port__52."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_b-at-neu__port__52.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_b-at-neu__port__52.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

load_pipeline = _mod.load_pipeline
branches_carrying = _mod.branches_carrying
preflight_checkout = _mod.preflight_checkout
blocker_closure = _mod.blocker_closure
ready_tickets = _mod.ready_tickets
dependency_paths = _mod.dependency_paths
lineage_paths = _mod.lineage_paths

p = load_pipeline(
    [],
    [],
    [],
    [],
    ["goal", "left", "right", "hub", "ping"],
    [
        ("goal", "left"),
        ("goal", "right"),
        ("left", "hub"),
        ("right", "hub"),
        ("hub", "ping"),
        ("ping", "hub"),
    ],
)
assert blocker_closure(p, "goal") == ["hub", "left", "ping", "right"]
assert blocker_closure(p, "hub") == ["hub", "ping"]
assert blocker_closure(p, "missing") == []

p = load_pipeline(
    ["main"],
    [],
    [("main", [".claude/port.config.json"])],
    [],
    ["only"],
    [],
)
assert branches_carrying(p, "ghost") == []
assert preflight_checkout(p, "ghost") == ["unknown checkout branch"]
assert lineage_paths(p, "main", "ghost") == []
assert lineage_paths(p, "ghost", "main") == []
assert dependency_paths(p, "only", "ghost") == []
assert dependency_paths(p, "ghost", "only") == []
assert ready_tickets(p, ["ghost", "only"]) == []

p = load_pipeline(
    [],
    [],
    [],
    [],
    ["task", "arm_a", "arm_b", "root", "loop_a", "loop_b", "loop_c"],
    [
        ("task", "arm_a"),
        ("task", "arm_b"),
        ("arm_a", "root"),
        ("arm_b", "root"),
        ("loop_a", "loop_b"),
        ("loop_b", "loop_c"),
        ("loop_c", "loop_a"),
    ],
)
assert dependency_paths(p, "task", "root") == [
    ["task", "arm_a", "root"],
    ["task", "arm_b", "root"],
]
assert dependency_paths(p, "task", "root", max_depth=2) == []
assert dependency_paths(p, "task", "task") == [["task"]]
assert dependency_paths(p, "loop_a", "loop_c", max_depth=2) == []
assert dependency_paths(p, "loop_a", "loop_c", max_depth=3) == [["loop_a", "loop_b", "loop_c"]]

p = load_pipeline(
    ["feat", "dev", "main"],
    [("feat", "dev"), ("dev", "main")],
    [],
    [],
    [],
    [],
)
assert lineage_paths(p, "feat", "main") == [["feat", "dev", "main"]]
assert lineage_paths(p, "feat", "main", max_depth=2) == []
assert lineage_paths(p, "main", "main") == [["main"]]
assert lineage_paths(p, "feat", "ghost") == []
assert lineage_paths(p, "ghost", "main") == []

p = load_pipeline(
    ["checkout", "alpha", "beta", "locked"],
    [],
    [
        ("checkout", []),
        ("alpha", [".claude/port.config.json"]),
        ("beta", [".claude/port.config.json", ".claude/settings.json"]),
        ("locked", [".claude/settings.json"]),
    ],
    [
        ("checkout", False),
        ("alpha", True),
        ("beta", True),
        ("locked", False),
    ],
    [],
    [],
)
assert preflight_checkout(p, "checkout") == [
    "missing .claude/port.config.json on checkout; present on alpha, beta",
    "missing .claude/settings.json on checkout; present on beta, locked",
]
assert preflight_checkout(p, "locked") == [
    "missing .claude/port.config.json on locked; present on alpha, beta",
    "missing permissions.allow in .claude/settings.json on locked",
]

p = load_pipeline(
    [],
    [],
    [],
    [],
    ["ship", "gate_a", "gate_b", "base"],
    [
        ("ship", "gate_a"),
        ("ship", "gate_b"),
        ("gate_a", "base"),
        ("gate_b", "base"),
    ],
)
assert ready_tickets(p) == ["base"]
assert ready_tickets(p, ["base"]) == ["gate_a", "gate_b"]
assert ready_tickets(p, ["base", "gate_a", "gate_b"]) == ["ship"]
assert ready_tickets(p, ["base", "gate_a", "gate_b", "ship"]) == []

print("iss_b-at-neu__port__52 ref OK")
print("iss_b-at-neu__port__52 ref OK")
