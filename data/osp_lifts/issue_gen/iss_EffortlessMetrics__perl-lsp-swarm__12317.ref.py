"""Reference harness for iss_EffortlessMetrics__perl-lsp-swarm__12317."""
import importlib.util
from pathlib import Path
_spec = importlib.util.spec_from_file_location("_mod", Path(__file__).with_name("iss_EffortlessMetrics__perl-lsp-swarm__12317.py"))
_mod = importlib.util.module_from_spec(_spec)
assert _spec.loader is not None
_spec.loader.exec_module(_mod)
candidate = {"sha": "abc", "profile_digest": "p1", "root_generation": 7, "toolchain": "1.82"}
r_local = {"id": "local_lexical", "group": "local_lexical", "candidate": candidate, "verdict": "pass", "current": True, "status": "pass", "depends_on": []}
r_world_c = {"id": "world_currentness", "group": "world_currentness", "candidate": candidate, "verdict": "pass", "current": True, "status": "pass", "depends_on": ["local_lexical"]}
r_world_n = {"id": "world_navigation", "group": "world_navigation", "candidate": candidate, "verdict": "pass", "current": True, "status": "pass", "depends_on": ["world_currentness"]}
r_world_r = {"id": "world_rename", "group": "world_rename", "candidate": candidate, "verdict": "pass", "current": True, "status": "pass", "depends_on": ["world_navigation"]}
r_rep = {"id": "representative", "group": "representative", "candidate": candidate, "verdict": "pass", "current": True, "status": "pass", "depends_on": []}
r_corr = {"id": "correctness", "group": "correctness", "candidate": candidate, "verdict": "pass", "current": True, "status": "pass", "depends_on": ["representative"]}
receipts = [r_local, r_world_c, r_world_n, r_world_r, r_rep, r_corr]
pkt = _mod.evaluate_cutline(candidate, receipts, [])
assert pkt["verdict"] == "pass", pkt
assert _mod.claim_ceiling(pkt) == "static_project"
# stale candidate key mismatch
bad_candidate = {"sha": "different", "profile_digest": "p1", "root_generation": 7, "toolchain": "1.82"}
bad = _mod.evaluate_cutline(bad_candidate, receipts, [])
assert bad["verdict"] == "not_proven"
# failed propagation via adjacency
r_fail = {"id": "world_navigation", "group": "world_navigation", "candidate": candidate, "verdict": "failed", "current": True, "status": "pass", "depends_on": ["world_currentness"]}
pkt2 = _mod.evaluate_cutline(candidate, [r_local, r_world_c, r_fail, r_world_r], [])
assert pkt2["verdict"] == "failed"
assert "world_rename" in pkt2["failed_closure"] or "world_navigation" in pkt2["failed_closure"]
# limitations lower ceiling
pkt3 = _mod.evaluate_cutline(candidate, receipts, ["bounded EIR excluded"])
assert _mod.claim_ceiling(pkt3) == "static_project_limited"
# cross candidate mixing
assert _mod.has_cross_candidate_mixing([{"candidate": candidate}, {"candidate": bad_candidate}]) is True
assert _mod.has_cross_candidate_mixing([{"candidate": candidate}, {"candidate": candidate}]) is False
# deterministic
a = _mod.evaluate_cutline(candidate, receipts, [])
b = _mod.evaluate_cutline(candidate, receipts, [])
assert _mod.is_deterministic(a, b) is True
# empty receipts not_proven
assert _mod.evaluate_cutline(candidate, [], [])["verdict"] == "not_proven"
print("iss_EffortlessMetrics__perl-lsp-swarm__12317 ref OK")
