"""Reference harness for iss_fbientrigo__dihiggs_hep_cross__17."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_fbientrigo__dihiggs_hep_cross__17.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_MODULE = Path(__file__).resolve().with_name("iss_fbientrigo__dihiggs_hep_cross__17.py")
_spec = importlib.util.spec_from_file_location("issue17", _MODULE)
assert _spec and _spec.loader
m = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = m
_spec.loader.exec_module(m)

s0 = m.fresh_handoff_store()
assert s0 == {"samples": {}, "deps": {}, "rev": {}, "nodes": {}, "points": {}}
s0 = m.register_sample("mg_prod", "pt_001", s0)
assert s0["samples"]["mg_prod"] == "pt_001"
assert s0["points"]["pt_001"] == "mg_prod"

s = m.fresh_handoff_store()
m.register_sample("mg_prod", "pt_001", s)
m.register_sample("pythia_decay", "pt_001", s)
m.register_sample("pack_aa", "pt_001", s)
m.register_sample("recast_input", "pt_001", s)
m.add_lineage_edge("mg_prod", "pythia_decay", s)
m.add_lineage_edge("mg_prod", "pack_aa", s)
m.add_lineage_edge("pythia_decay", "recast_input", s)
m.add_lineage_edge("pack_aa", "recast_input", s)
got = m.reachable_samples("mg_prod", s)
assert got == ["pack_aa", "recast_input", "pythia_decay"]
assert sum(1 for sid in got if sid == "recast_input") == 1

s1 = m.fresh_handoff_store()
for sid in ("mg_prod", "pythia_decay", "pack_aa", "recast_input"):
    m.register_sample(sid, "pt_001", s1)
m.add_lineage_edge("mg_prod", "pack_aa", s1)
m.add_lineage_edge("pack_aa", "recast_input", s1)
m.add_lineage_edge("mg_prod", "pythia_decay", s1)
m.add_lineage_edge("pythia_decay", "recast_input", s1)
s2 = m.fresh_handoff_store()
for sid in ("mg_prod", "pythia_decay", "pack_aa", "recast_input"):
    m.register_sample(sid, "pt_002", s2)
m.add_lineage_edge("mg_prod", "pythia_decay", s2)
m.add_lineage_edge("pythia_decay", "recast_input", s2)
m.add_lineage_edge("mg_prod", "pack_aa", s2)
m.add_lineage_edge("pack_aa", "recast_input", s2)
assert m.reachable_samples("mg_prod", s1) == m.reachable_samples("mg_prod", s2)

s = m.fresh_handoff_store()
m.register_sample("mg_prod", "pt_001", s)
try:
    m.direct_downstream("missing", s)
    raise AssertionError("expected KeyError for unknown sample")
except KeyError:
    pass
try:
    m.add_lineage_edge("mg_prod", "missing", s)
    raise AssertionError("expected KeyError for unknown lineage target")
except KeyError:
    pass

s = m.fresh_handoff_store()
m.register_sample("mg_prod", "pt_001", s)
m.register_sample("hepmc_out", "pt_001", s)
m.add_lineage_edge("mg_prod", "hepmc_out", s)
m.add_lineage_edge("mg_prod", "hepmc_out", s)
assert m.direct_downstream("mg_prod", s) == ["hepmc_out"]
rep = m.handoff_report("mg_prod", s)
assert rep["reach_count"] == 1

s = m.fresh_handoff_store()
m.register_sample("mg_prod", "pt_042", s)
m.register_sample("recast_input", "pt_042", s)
m.add_lineage_edge("mg_prod", "recast_input", s)
rep = m.handoff_report("mg_prod", s)
assert rep == {
    "point_id": "pt_042",
    "direct": ["recast_input"],
    "reach": ["recast_input"],
    "reach_count": 1,
}
assert m.direct_upstream("recast_input", s) == ["mg_prod"]
print("iss_fbientrigo__dihiggs_hep_cross__17 ref OK")
