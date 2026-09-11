"""Reference harness for iss_Herd-OS__herd__1050."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_Herd-OS__herd__1050.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

wf = _mod.load_review_workflow(
    ["pending", "running", "approved", "changes_requested", "failed", "timed_out", "unparseable"],
    [
        ("pending", "running"),
        ("running", "approved"),
        ("running", "changes_requested"),
        ("running", "failed"),
        ("running", "timed_out"),
        ("running", "unparseable"),
    ],
)
assert _mod.reachable_statuses(wf, "running") == [
    "approved", "changes_requested", "failed", "timed_out", "unparseable"
]
assert _mod.can_transition(wf, "running", "timed_out") is True
assert _mod.can_transition(wf, "running", "timeout") is False
assert _mod.normalize_status(wf, "timeout") == "timed_out"
assert _mod.normalize_status(wf, "bogus") is None

print("iss_Herd-OS__herd__1050 ref OK")
