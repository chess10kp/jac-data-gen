"""Reference harness: exercises every public function of iss_OpenCHAMI__tokensmith__37."""
from iss_OpenCHAMI__tokensmith__37 import (
    RevocationError,
    ScopeViolation,
    TokenRegistry,
)

reg = TokenRegistry()
sess_claims = {"amr": ["pwd", "otp"], "acr": "urn:mfa:required", "auth_time": 1719708600}
reg.issue("sess", scopes=["read", "write", "admin"], claims=sess_claims)
reg.issue("api1", scopes=["read"], parent_id="sess")
reg.issue("api2", scopes=["read", "write"], parent_id="sess")
reg.issue("shortlived", scopes=["admin"], claims={"acr": "urn:mfa:required"}, parent_id="sess")
reg.issue("nested", scopes=["read"], parent_id="api1")

# Claim inheritance: nearest-wins merge along the ancestor chain.
assert reg.effective_claims("api1") == sess_claims
assert reg.effective_claims("shortlived")["acr"] == "urn:mfa:required"
assert reg.effective_claims("nested")["auth_time"] == 1719708600
assert reg.effective_claims("shortlived")["amr"] == ["pwd", "otp"]
assert reg.effective_claims("sess") == sess_claims

# Scope degradation enforced at issue time.
try:
    reg.issue("bad", scopes=["sudo"], parent_id="api1")
    raise SystemExit("expected ScopeViolation")
except ScopeViolation:
    pass

# Revocation cascades to every descendant.
assert reg.revoke("api1") == ["api1", "nested"]
assert not reg.is_active("api1")
assert reg.is_active("shortlived")         # moved under sess, unaffected by api1 revoke
assert reg.is_active("api2")               # sibling unaffected
assert reg.is_active("sess")

# Double revoke is a directed error.
try:
    reg.revoke("api1")
    raise SystemExit("expected RevocationError")
except RevocationError:
    pass

# Cannot issue under a revoked parent.
try:
    reg.issue("orphan", scopes=["read"], parent_id="api1")
    raise SystemExit("expected KeyError")
except KeyError:
    pass

# Deep chains: revoking the root kills everything.
deep = TokenRegistry()
deep.issue("t0", scopes=["read"])
for i in range(1, 5):
    deep.issue("t%d" % i, scopes=["read"], parent_id="t%d" % (i - 1))
assert deep.is_active("t4")
assert deep.revoke("t0") == ["t0", "t1", "t2", "t3", "t4"]
assert all(not deep.is_active("t%d" % i) for i in range(5))

# Corrupt cycle in parent pointers does not hang ascent.
cyc = TokenRegistry()
cyc.parent_of["x"] = "y"
cyc.parent_of["y"] = "x"
cyc.claims["x"] = {"acr": "a"}
cyc.claims["y"] = {"acr": "b"}
cyc.scopes_of = {"x": set(), "y": set()}
cyc.children_of = {"x": [], "y": []}
assert cyc._ancestor_chain("x") == ["y"]          # stops, no infinite loop
assert cyc.effective_claims("x")["acr"] == "a"  # self claim wins over cycled ancestor

# Unknown root token id: active-by-default lookup misses cleanly.
solo = TokenRegistry()
solo.issue("only", scopes=[])
assert solo.is_active("only")
assert solo.effective_claims("only") == {}
