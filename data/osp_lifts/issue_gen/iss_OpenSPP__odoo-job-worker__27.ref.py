"""Reference harness for iss_OpenSPP__odoo-job-worker__27."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_OpenSPP__odoo-job-worker__27.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
CHAIN = _mod.build_job_registry(
    [
        {"id": "A", "parent_id": None, "status": "running"},
        {"id": "B", "parent_id": "A", "status": "waiting"},
        {"id": "C", "parent_id": "B", "status": "waiting"},
    ]
)
assert _mod.direct_children(CHAIN, "A") == ["B"]
assert _mod.descendant_job_ids(CHAIN, "A") == ["B", "C"]
assert _mod.reclaim_exhausted_cascade(CHAIN, "A") == {"failed": ["A"], "cascaded": ["B"]}
assert CHAIN.jobs["C"]["status"] == "waiting"
assert _mod.stuck_waiting_jobs(CHAIN) == ["C"]
assert _mod.gc_collectible_ids(CHAIN) == ["A", "B"]

ORM = _mod.build_job_registry(
    [
        {"id": "A", "parent_id": None, "status": "failed"},
        {"id": "B", "parent_id": "A", "status": "waiting"},
        {"id": "C", "parent_id": "B", "status": "waiting"},
    ]
)
assert _mod.raw_sql_parent_cascade(ORM, "A") == ["B"]
assert _mod.stuck_waiting_jobs(ORM) == ["C"]
ORM2 = _mod.build_job_registry(
    [
        {"id": "A", "parent_id": None, "status": "failed"},
        {"id": "B", "parent_id": "A", "status": "waiting"},
        {"id": "C", "parent_id": "B", "status": "waiting"},
    ]
)
assert _mod.orm_cascade_children_on_parent_failure(ORM2, "A") == ["B", "C"]
assert _mod.stuck_waiting_jobs(ORM2) == []

TREE = _mod.build_job_registry(
    [
        {"id": "A", "parent_id": None, "status": "waiting"},
        {"id": "B", "parent_id": "A", "status": "waiting"},
        {"id": "C", "parent_id": "A", "status": "waiting"},
        {"id": "D", "parent_id": "B", "status": "waiting"},
        {"id": "E", "parent_id": "C", "status": "waiting"},
        {"id": "F", "parent_id": "D", "status": "waiting"},
    ]
)
assert _mod.direct_children(TREE, "A") == ["B", "C"]
assert _mod.descendant_job_ids(TREE, "A") == ["B", "C", "D", "E", "F"]

FAN = _mod.build_job_registry(
    [
        {"id": "hub", "parent_id": None, "status": "failed"},
        {"id": "z", "parent_id": "hub", "status": "waiting"},
        {"id": "a", "parent_id": "hub", "status": "waiting"},
        {"id": "a1", "parent_id": "a", "status": "waiting"},
    ]
)
assert _mod.descendant_job_ids(FAN, "hub") == ["a", "a1", "z"]
assert _mod.raw_sql_parent_cascade(FAN, "hub") == ["a", "z"]
assert _mod.stuck_waiting_jobs(FAN) == ["a1"]
assert _mod.gc_collectible_ids(FAN) == ["a", "hub", "z"]

assert _mod.direct_children(CHAIN, "ghost") == []
assert _mod.descendant_job_ids(CHAIN, "ghost") == []
assert _mod.raw_sql_parent_cascade(CHAIN, "ghost") == []
assert _mod.orm_cascade_children_on_parent_failure(CHAIN, "ghost") == []
assert _mod.reclaim_exhausted_cascade(CHAIN, "ghost") == {"failed": [], "cascaded": []}
assert _mod.stuck_waiting_jobs(CHAIN) == ["C"]
assert _mod.gc_collectible_ids(CHAIN) == ["A", "B"]
print("iss_OpenSPP__odoo-job-worker__27 ref OK")
