"""Reference harness for iss_EXXETA__exxperts__49."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_EXXETA__exxperts__49.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

idx = _mod.load_skill_index(
    ["root", "pkg", "skills", "s1", "s2"],
    [("root", "pkg"), ("pkg", "skills"), ("skills", "s1"), ("skills", "s2")],
    skill_dirs=["s1", "s2"],
)
assert _mod.discover_skills(idx, "root") == ["s1", "s2"]
assert _mod.scan_visit_count(idx, "root") == 5
loop = _mod.load_skill_index(["a", "b"], [], symlinks=[("a", "b"), ("b", "a")])
assert _mod.has_symlink_cycle(loop, "a") is True

print("iss_EXXETA__exxperts__49 ref OK")
