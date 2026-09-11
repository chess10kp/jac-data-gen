"""Reference harness for iss_Jacob-Lasky__minecraft-recipe-graph__337."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_Jacob-Lasky__minecraft-recipe-graph__337.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

tree = _mod.load_widgets(
    ["root", "panel", "slot", "icon", "tip"],
    [("root", "panel"), ("panel", "slot"), ("slot", "icon"), ("icon", "tip")],
    hovered_id="tip",
)
assert _mod.hovered_ancestors(tree) == ["tip", "icon", "slot", "panel", "root"]
assert _mod.hover_depth(tree) == 4
assert _mod.safe_hover_ids(tree) == []

panel_tree = _mod.load_widgets(
    ["root", "panel", "a", "b", "leaf"],
    [("root", "panel"), ("panel", "a"), ("panel", "b"), ("a", "leaf"), ("b", "leaf")],
    hovered_id="panel",
)
assert _mod.safe_hover_ids(panel_tree) == ["a", "b", "leaf"]

empty = _mod.load_widgets(["solo"], [], hovered_id=None)
assert _mod.hovered_ancestors(empty) == []

print("iss_Jacob-Lasky__minecraft-recipe-graph__337 ref OK")
