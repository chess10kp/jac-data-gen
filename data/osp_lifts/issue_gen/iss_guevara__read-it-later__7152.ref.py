"""Reference harness for iss_guevara__read-it-later__7152."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_guevara__read-it-later__7152.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
model = _mod.load_hierarchy(
    [
        ("root", 1, 10, None),
        ("a", 2, 5, "root"),
        ("b", 6, 9, "root"),
        ("a1", 3, 4, "a"),
        ("a2", 4, 5, "a"),
    ]
)

assert _mod.adj_session_descendants(model, "root") == ["a", "a1", "a2", "b"]
assert _mod.nested_spatial_subtree(model, "root") == ["a", "a1", "a2", "b"]
assert _mod.adj_session_descendants(model, "a") == ["a1", "a2"]
assert _mod.nested_spatial_subtree(model, "a") == ["a1", "a2"]
assert _mod.adj_session_depth(model, "a1") == 2
assert _mod.nested_spatial_depth(model, "a1") == 2
assert _mod.adj_session_depth(model, "a2") == 2
assert _mod.nested_spatial_depth(model, "a2") == 2
assert _mod.models_agree_on_subtree(model, "root") is True
assert _mod.models_agree_on_subtree(model, "a") is True
assert _mod.models_agree_on_subtree(model, "b") is True

assert _mod.adj_session_descendants(model, "missing") == []
assert _mod.nested_spatial_subtree(model, "missing") == []
assert _mod.adj_session_depth(model, "missing") == -1
assert _mod.nested_spatial_depth(model, "missing") == -1

shuffled = _mod.load_hierarchy(
    [
        ("root", 1, 12, None),
        ("right", 8, 11, "root"),
        ("left", 2, 7, "root"),
        ("join", 5, 6, "left"),
    ]
)
assert _mod.adj_session_descendants(shuffled, "root") == ["join", "left", "right"]
assert _mod.nested_spatial_subtree(shuffled, "root") == ["join", "left", "right"]
assert _mod.models_agree_on_subtree(shuffled, "root") is True
assert _mod.adj_session_descendants(shuffled, "left") == ["join"]
assert _mod.nested_spatial_subtree(shuffled, "left") == ["join"]

try:
    _mod.load_hierarchy([("orphan", 1, 2, "missing")])
    raise AssertionError("expected KeyError")
except KeyError:
    pass
print("iss_guevara__read-it-later__7152 ref OK")
