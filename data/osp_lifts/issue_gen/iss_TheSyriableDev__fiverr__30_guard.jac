"""Role-based access control, lifted to OSP.

Roles become Role nodes carrying their grant and deny lists, and the
parent_id chain becomes a typed Extends edge (child to parent). The
while-loop chain walk and merge become a walker over Extends edges: each
role has exactly one parent, so step order is the chain order nearest
first, and first-mention-wins (deny beating allow within one role)
reproduces the nearest-mention override exactly. The claim map is the
malformed-hierarchy cycle policy; output stays sorted.
Ref: TheSyriableDev/fiverr#30
"""
node Role {
    has rid: str;
    has grants: list[str];
    has denies: list[str];
}
edge Extends {}

"""Loader handle: role ids resolve through this lookup map."""
obj RoleBook {
    has roles: dict[str, Role];

    def resolve(rid: str) -> Role | None {
        return self.roles.get(rid);
    }
}

"""Deterministic fresh-graph builder from role rows in any order."""
def load_roles(roles: list[dict]) -> RoleBook {
    rb = RoleBook(roles={});
    for row in roles {
        r = Role(rid=row["id"], grants=row["permissions"], denies=row["denied"]);
        root ++> r;
        rb.roles[row["id"]] = r;
    }
    for row in roles {
        pid = row.get("parent_id");
        if pid is not None {
            child = rb.roles.get(row["id"]);
            parent = rb.roles.get(pid);
            if child is None {
                continue;
            }
            if parent is None {
                continue;  # dangling parent_id: chain stops after the role
            }
            child +>:Extends:+> parent;
        }
    }
    return rb;
}

walker InheritWalk {
    has claimed: dict[str, bool] = {};
    has decided: dict[str, bool] = {};

    can step with Role entry {
        # Cycle policy: one visit per role (malformed-hierarchy guard).
        if here.rid in self.claimed {
            skip;
        }
        self.claimed[here.rid] = True;
        # Nearest mention wins: this role is closer than its ancestors,
        # and within one role a deny beats an allow.
        for p in here.denies {
            if p not in self.decided {
                self.decided[p] = False;
            }
        }
        for p in here.grants {
            if p not in self.decided {
                self.decided[p] = True;
            }
        }
        visit [->:Extends:->];
    }
}

"""Sorted list of effective grants for ``role`` (nearest mention wins)."""
def effective_permissions(roles: list[dict], role: str) -> list {
    rb = load_roles(roles);
    start = rb.resolve(role);
    if start is None {
        return [];
    }
    w = start spawn InheritWalk(claimed={}, decided={});
    out: list[str] = [];
    for p in w.decided.keys() {
        if w.decided[p] {
            out.append(p);
        }
    }
    return sorted(out);
}

"""True iff ``perm`` is an effective grant of ``role``."""
def can(roles: list[dict], role: str, perm: str) -> bool {
    return perm in effective_permissions(roles, role);
}


test "canonical hierarchy inherits grants up the chain" {
    ROLES = [
        {"id": "superadmin", "parent_id": "admin", "permissions": ["platform:settings"], "denied": []},
        {"id": "seller", "parent_id": "buyer", "permissions": ["gig:create", "gig:edit", "order:manage"], "denied": []},
        {"id": "guest", "parent_id": None, "permissions": ["browse:gigs", "read:profile"], "denied": []},
        {"id": "admin", "parent_id": "seller", "permissions": ["user:ban", "gig:feature"], "denied": []},
        {"id": "buyer", "parent_id": "guest", "permissions": ["order:create", "order:pay"], "denied": []},
    ];
    assert effective_permissions(ROLES, "guest") == ["browse:gigs", "read:profile"];
    assert effective_permissions(ROLES, "buyer") == ["browse:gigs", "order:create", "order:pay", "read:profile"];
    assert effective_permissions(ROLES, "seller") == ["browse:gigs", "gig:create", "gig:edit", "order:create", "order:manage", "order:pay", "read:profile"];
    assert effective_permissions(ROLES, "superadmin") == ["browse:gigs", "gig:create", "gig:edit", "gig:feature", "order:create", "order:manage", "order:pay", "platform:settings", "read:profile", "user:ban"];
    assert can(ROLES, "seller", "browse:gigs") == True;
    assert can(ROLES, "buyer", "gig:create") == False;
    assert can(ROLES, "guest", "order:create") == False;
    assert can(ROLES, "superadmin", "user:ban") == True;
}

test "nearest mention overrides ancestors in both directions" {
    OVR = [
        {"id": "base", "parent_id": None, "permissions": ["report:export", "cache:warm"], "denied": []},
        {"id": "mid", "parent_id": "base", "permissions": [], "denied": ["report:export"]},
        {"id": "top", "parent_id": "mid", "permissions": ["report:export"], "denied": []},
    ];
    assert effective_permissions(OVR, "base") == ["cache:warm", "report:export"];
    assert effective_permissions(OVR, "mid") == ["cache:warm"];
    assert effective_permissions(OVR, "top") == ["cache:warm", "report:export"];
    assert can(OVR, "mid", "report:export") == False;
    assert can(OVR, "top", "report:export") == True;
}

test "deny beats allow within one role" {
    TIE = [{"id": "solo", "parent_id": None, "permissions": ["a"], "denied": ["a"]}];
    assert effective_permissions(TIE, "solo") == [];
    assert can(TIE, "solo", "a") == False;
}

test "unknown role has no grants" {
    ROLES = [
        {"id": "guest", "parent_id": None, "permissions": ["browse:gigs"], "denied": []},
    ];
    assert effective_permissions(ROLES, "ghost") == [];
    assert can(ROLES, "ghost", "browse:gigs") == False;
}

test "dangling parent id stops the chain after the role" {
    DANGLE = [{"id": "orphan", "parent_id": "nowhere", "permissions": ["p:one"], "denied": []}];
    assert effective_permissions(DANGLE, "orphan") == ["p:one"];
}
