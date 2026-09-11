"""Reference harness for iss_BharatDBPG__BharatDBMS-PG__3005."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_BharatDBPG__BharatDBMS-PG__3005.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

g = _mod.load_view_graph(
    ["root", "v1", "v2", "leaf"],
    [("root", "v1"), ("root", "v2"), ("v1", "leaf"), ("v2", "leaf")],
)
lv = _mod.reachable_with_levels(g, "root")
assert lv["leaf"] == 2
assert lv["root"] == 0

print("iss_BharatDBPG__BharatDBMS-PG__3005 ref OK")
