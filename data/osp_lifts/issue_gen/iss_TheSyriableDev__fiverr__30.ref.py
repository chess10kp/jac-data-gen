"""Reference harness: exercises every public function of iss_TheSyriableDev__fiverr__30."""
import importlib

mod = importlib.import_module("iss_TheSyriableDev__fiverr__30")
effective_permissions = mod.effective_permissions
can = mod.can

# Canonical marketplace hierarchy, rows listed child-first to pin that
# resolution needs no top-down order.
ROLES = [
    {"id": "superadmin", "parent_id": "admin", "permissions": ["platform:settings"], "denied": []},
    {"id": "seller", "parent_id": "buyer", "permissions": ["gig:create", "gig:edit", "order:manage"], "denied": []},
    {"id": "guest", "parent_id": None, "permissions": ["browse:gigs", "read:profile"], "denied": []},
    {"id": "admin", "parent_id": "seller", "permissions": ["user:ban", "gig:feature"], "denied": []},
    {"id": "buyer", "parent_id": "guest", "permissions": ["order:create", "order:pay"], "denied": []},
]

assert effective_permissions(ROLES, "guest") == ["browse:gigs", "read:profile"]
assert effective_permissions(ROLES, "buyer") == ["browse:gigs", "order:create", "order:pay", "read:profile"]
assert effective_permissions(ROLES, "seller") == [
    "browse:gigs", "gig:create", "gig:edit", "order:create", "order:manage", "order:pay", "read:profile",
]
assert effective_permissions(ROLES, "superadmin") == [
    "browse:gigs", "gig:create", "gig:edit", "gig:feature", "order:create", "order:manage",
    "order:pay", "platform:settings", "read:profile", "user:ban",
]

assert can(ROLES, "seller", "browse:gigs") is True
assert can(ROLES, "buyer", "gig:create") is False
assert can(ROLES, "guest", "order:create") is False
assert can(ROLES, "superadmin", "user:ban") is True

# Nearest-mention override: a child deny shadows an ancestor grant, and a
# grandchild re-grant shadows the deny again.
OVR = [
    {"id": "base", "parent_id": None, "permissions": ["report:export", "cache:warm"], "denied": []},
    {"id": "mid", "parent_id": "base", "permissions": [], "denied": ["report:export"]},
    {"id": "top", "parent_id": "mid", "permissions": ["report:export"], "denied": []},
]
assert effective_permissions(OVR, "base") == ["cache:warm", "report:export"]
assert effective_permissions(OVR, "mid") == ["cache:warm"]
assert effective_permissions(OVR, "top") == ["cache:warm", "report:export"]
assert can(OVR, "mid", "report:export") is False
assert can(OVR, "top", "report:export") is True

# Within one role, deny beats allow.
TIE = [{"id": "solo", "parent_id": None, "permissions": ["a"], "denied": ["a"]}]
assert effective_permissions(TIE, "solo") == []
assert can(TIE, "solo", "a") is False

# Unknown role: no grants, no capability.
assert effective_permissions(ROLES, "ghost") == []
assert can(ROLES, "ghost", "browse:gigs") is False

# Dangling parent_id: the chain stops after the role itself.
DANGLE = [{"id": "orphan", "parent_id": "nowhere", "permissions": ["p:one"], "denied": []}]
assert effective_permissions(DANGLE, "orphan") == ["p:one"]

print("iss_TheSyriableDev__fiverr__30 ref OK")
