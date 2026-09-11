import importlib.util
from pathlib import Path

spec = importlib.util.spec_from_file_location("iss_ELares__IronTraffic__140", Path(__file__).with_suffix(".py"))
mod = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(mod)

REFS = [("svc", "db"), ("svc", "ghost")]
KNOWN = {"svc", "db"}
EDGES = [("a", "b"), ("b", "c"), ("c", "a")]
LINE = [("r", "s"), ("s", "t")]

assert mod.resolve_refs(REFS, KNOWN) == (["svc->db"], ["ghost"])
assert mod.detect_cycles(EDGES) == ["a", "b", "c"]
assert mod.budgeted_reach("r", LINE, 1) == ["r", "s"]
assert mod.budgeted_reach("missing", LINE) == []
print("ok")
