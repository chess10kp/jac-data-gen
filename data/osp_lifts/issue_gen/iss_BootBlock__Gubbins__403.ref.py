"""Reference harness for iss_BootBlock__Gubbins__403."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_BootBlock__Gubbins__403.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

reg = _mod.load_backlog(
    [
        ("epic-sync", 2, None),
        ("502", 1, "epic-sync"),
        ("633", 2, "epic-sync"),
        ("sub-fix", 3, "633"),
    ],
)
assert _mod.ancestor_issues(reg, "sub-fix") == ["epic-sync", "633", "sub-fix"]
assert _mod.effective_tier(reg, "sub-fix") == 2
assert _mod.subtree_issues(reg, "epic-sync") == [
    "502", "633", "epic-sync", "sub-fix"
]
assert _mod.effective_tier(reg, "502") == 1
assert _mod.ancestor_issues(reg, "ghost") == []

print("iss_BootBlock__Gubbins__403 ref OK")
