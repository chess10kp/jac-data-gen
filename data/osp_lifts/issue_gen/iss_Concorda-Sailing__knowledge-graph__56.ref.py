"""Reference harness for iss_Concorda-Sailing__knowledge-graph__56."""
import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_Concorda-Sailing__knowledge-graph__56.py"),
)
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)

g = _mod.load_dossiers(
    ["fn_a", "fn_b", "cls_c", "mod_d"],
    [("fn_a", "fn_b"), ("fn_a", "cls_c"), ("fn_b", "mod_d")],
)
assert _mod.outbound_reach(g, "fn_a") == ["cls_c", "fn_b", "mod_d"]

print("iss_Concorda-Sailing__knowledge-graph__56 ref OK")
