"""Role-based access control with inherited permissions.

Roles form a hierarchy (Guest -> Buyer -> Seller -> Admin -> SuperAdmin)
via ``parent_id`` pointers: ``effective_permissions`` walks up the chain
with a while loop and merges grants, where the NEAREST mention of a
permission wins — a role nearer the queried role overrides what its
ancestors say, and when one role mentions a permission in both its
``denied`` and ``permissions`` lists, the deny wins. Effective grants
are returned sorted.
Ref: TheSyriableDev/fiverr#30
"""
"""Sorted list of effective grants for ``role``.

    ``roles`` is a list of ``{"id": ..., "parent_id": ...,
    "permissions": [...], "denied": [...]}`` rows in any order. The
    chain from ``role`` upward is walked nearest first; the first role
    in the chain to mention a permission decides it, deny beating allow
    within a single role. An unknown ``role`` has no grants.
    """
def effective_permissions(roles: Any, role: Any) -> object {
    by_id: dict = {r["id"]: r for r in roles};
    chain: list = [];
    cur = by_id.get(role);
    while (cur is not None) {
        chain.append(cur);
        pid = cur.get("parent_id");
        cur = by_id.get(pid) if (pid is not None) else None;
    }
    decided: dict = {};
    for r in chain {
        for p in r["denied"] {
            decided.setdefault(p, False);
        }
        for p in r["permissions"] {
            decided.setdefault(p, True);
        }
    }
    return sorted(
        p
        for (p, ok) in decided.items()
        if ok
    );
}

"""True iff ``perm`` is an effective grant of ``role``."""
def `can(roles: Any, role: Any, perm: Any) -> object {
    return (perm in effective_permissions(roles, role));
}

