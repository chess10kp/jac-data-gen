"""Reference harness for iss_opena2a-org__hackmyagent__379."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_opena2a-org__hackmyagent__379.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
from pathlib import Path

_mod_path = Path(__file__).with_name("iss_opena2a-org__hackmyagent__379.py")
_spec = importlib.util.spec_from_file_location("iss379", _mod_path)
assert _spec is not None and _spec.loader is not None
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)

ConfigKey = _mod.ConfigKey
connect_child = _mod.connect_child
build_issue_tree = _mod.build_issue_tree
build_diamond_tree = _mod.build_diamond_tree
grant_line_at = _mod.grant_line_at
structure_locate = _mod.structure_locate
collect_allow_lines = _mod.collect_allow_lines
_children = _mod._children

g = build_issue_tree()
assert structure_locate(g, "Read(**/*.key)", "allow") == 5
assert structure_locate(g, "Read(**/*.key)", "deny") == 4

g = build_issue_tree()
assert grant_line_at(g, "permissions.missing[0]") is None

g = build_diamond_tree()
assert structure_locate(g, "Read(**/*.key)", "allow") == 7

g = build_issue_tree()
deep = ConfigKey(
    "deep",
    "allow[0]",
    "permissions.deep.allow[0]",
    99,
    "allow",
    "Read(secret/**)",
    14,
)
perms_node = _children(g)[0]
connect_child(perms_node, deep)
assert grant_line_at(g, "permissions.deep.allow[0]", 13) is None
paths = collect_allow_lines(g, 13)
assert "permissions.deep.allow[0]" not in paths

g = build_issue_tree()
paths = collect_allow_lines(g, 13)
assert paths == sorted(paths)
assert len(paths) == 2

g = build_issue_tree()
assert grant_line_at(g, "permissions.allow[0]") == 3

g = build_diamond_tree()
assert grant_line_at(g, "permissions.shared.grant") == 7

g = build_issue_tree()
assert collect_allow_lines(g, 1) == []
print("iss_opena2a-org__hackmyagent__379 ref OK")
