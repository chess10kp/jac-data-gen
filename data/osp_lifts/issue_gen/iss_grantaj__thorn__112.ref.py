"""Reference harness for iss_grantaj__thorn__112."""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "_mod",
    Path(__file__).with_name("iss_grantaj__thorn__112.py"),
)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["_mod"] = _mod  # dataclass/string-annotation resolution needs it
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
import importlib.util
import sys
from pathlib import Path

_MODULE = Path(__file__).resolve().with_name("iss_grantaj__thorn__112.py")
_spec = importlib.util.spec_from_file_location("issue112", _MODULE)
assert _spec and _spec.loader
m = importlib.util.module_from_spec(_spec)
sys.modules[_spec.name] = m
_spec.loader.exec_module(m)

s0 = m.fresh_proof_store()
assert s0 == {"units": {}, "deps": {}, "rev": {}, "nodes": {}, "records": {}, "cones": {}}
s0 = m.register_proof_unit("lemma_a", s0)
assert s0["units"]["lemma_a"] is True
assert s0["records"]["lemma_a"] == {"state": m.STATE_NEVER, "reason": ""}

s = m.fresh_proof_store()
m.register_proof_unit("lemma_a", s)
m.register_proof_unit("lemma_b", s)
m.register_proof_unit("lemma_c", s)
m.register_proof_unit("theorem_x", s)
m.add_proof_dep("lemma_a", "lemma_b", s)
m.add_proof_dep("lemma_a", "lemma_c", s)
m.add_proof_dep("lemma_b", "theorem_x", s)
m.add_proof_dep("lemma_c", "theorem_x", s)
got = m.reachable_units("lemma_a", s)
assert got == ["lemma_b", "theorem_x", "lemma_c"]
assert sum(1 for uid in got if uid == "theorem_x") == 1
assert m.direct_downstream("lemma_a", s) == ["lemma_b", "lemma_c"]

s1 = m.fresh_proof_store()
for uid in ("lemma_a", "lemma_b", "lemma_c", "theorem_x"):
    m.register_proof_unit(uid, s1)
m.add_proof_dep("lemma_a", "lemma_c", s1)
m.add_proof_dep("lemma_c", "theorem_x", s1)
m.add_proof_dep("lemma_a", "lemma_b", s1)
m.add_proof_dep("lemma_b", "theorem_x", s1)
s2 = m.fresh_proof_store()
for uid in ("lemma_a", "lemma_b", "lemma_c", "theorem_x"):
    m.register_proof_unit(uid, s2)
m.add_proof_dep("lemma_a", "lemma_b", s2)
m.add_proof_dep("lemma_b", "theorem_x", s2)
m.add_proof_dep("lemma_a", "lemma_c", s2)
m.add_proof_dep("lemma_c", "theorem_x", s2)
assert m.reachable_units("lemma_a", s1) == m.reachable_units("lemma_a", s2)

s = m.fresh_proof_store()
m.register_proof_unit("lemma_a", s)
try:
    m.direct_downstream("missing", s)
    raise AssertionError("expected KeyError for unknown unit")
except KeyError:
    pass
try:
    m.add_proof_dep("lemma_a", "missing", s)
    raise AssertionError("expected KeyError for unknown dep target")
except KeyError:
    pass

s = m.fresh_proof_store()
m.register_proof_unit("lemma_a", s)
m.register_proof_unit("lemma_b", s)
m.register_proof_unit("theorem_x", s)
m.register_proof_unit("corollary_y", s)
m.add_proof_dep("lemma_a", "lemma_b", s)
m.add_proof_dep("lemma_b", "theorem_x", s)
m.add_proof_dep("lemma_a", "corollary_y", s)
m.attach_review_record("lemma_a", m.STATE_LOCAL, "manuscript edit", s)
m.record_invalidation_cone("lemma_a", ["lemma_b", "theorem_x"], s)
assert m.invalidation_cone("lemma_a", s) == ["lemma_b", "theorem_x"]
rep = m.freshness_report("lemma_a", s)
assert rep["cone"] == ["lemma_b", "theorem_x"]
assert rep["reach"] == ["corollary_y", "lemma_b", "theorem_x"]
assert rep["reach_count"] == 3
assert rep["state"] == m.STATE_LOCAL
assert rep["reason"] == "manuscript edit"
assert rep["direct"] == ["corollary_y", "lemma_b"]
assert s["records"]["corollary_y"]["state"] == m.STATE_NEVER

s = m.fresh_proof_store()
m.register_proof_unit("lemma_a", s)
m.register_proof_unit("lemma_b", s)
m.register_proof_unit("theorem_x", s)
m.register_proof_unit("theorem_z", s)
m.add_proof_dep("lemma_a", "theorem_x", s)
m.add_proof_dep("lemma_b", "theorem_z", s)
m.attach_review_record("lemma_a", m.STATE_LOCAL, "local edit", s)
m.attach_review_record("theorem_z", m.STATE_REUSED, "prior review valid", s)
m.record_invalidation_cone("lemma_a", ["theorem_x"], s)
rep_stale = m.freshness_report("lemma_a", s)
rep_reuse = m.freshness_report("theorem_z", s)
assert rep_stale["state"] == m.STATE_LOCAL
assert rep_reuse["state"] == m.STATE_REUSED
assert rep_reuse["reason"] == "prior review valid"
assert m.invalidation_cone("lemma_a", s) == ["theorem_x"]
assert m.direct_downstream("lemma_b", s) == ["theorem_z"]
assert m.direct_downstream("theorem_z", s) == []
print("iss_grantaj__thorn__112 ref OK")
