"""Ashutosh-Malve/sentinel-rbac#7 — org parent chain for materialized-path lookup."""

node Organization {
    has oid: str;
}

edge ChildOf {}

obj OrgRegistry {
    has orgs: dict[str, Organization] = {};
}

def load_org_registry(orgs: list[tuple[str, str | None]]) -> OrgRegistry {
    reg = OrgRegistry();
    for (oid, parent) in orgs {
        if parent is not None and reg.orgs.get(parent, None) is None {
            raise KeyError("unknown parent organization");
        }
        nd = Organization(oid=oid);
        root ++> nd;
        reg.orgs[oid] = nd;
        if parent is not None {
            p = reg.orgs.get(parent, None);
            if p is not None { p +>:ChildOf:+> nd; }
        }
    }
    return reg;
}

def _walk_up(reg: OrgRegistry, org_id: str) -> list[str] {
    nd = reg.orgs.get(org_id, None);
    if nd is None { return []; }
    chain: list[str] = [];
    cur: Organization | None = nd;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur.oid in seen { break; }
        seen[cur.oid] = True;
        chain.append(cur.oid);
        parent: Organization | None = None;
        for p in [cur <-:ChildOf:<-][?:Organization] {
            parent = p;
            break;
        }
        cur = parent;
    }
    rev: list[str] = [];
    for i in range(len(chain) - 1, -1, -1) { rev.append(chain[i]); }
    return rev;
}

def ancestor_path(reg: OrgRegistry, org_id: str) -> list[str] {
    return _walk_up(reg, org_id);
}

def materialized_path(reg: OrgRegistry, org_id: str) -> str {
    parts = _walk_up(reg, org_id);
    if len(parts) == 0 { return ""; }
    return "/" + "/".join(parts);
}

def org_depth(reg: OrgRegistry, org_id: str) -> int {
    path = _walk_up(reg, org_id);
    return len(path) - 1 if len(path) > 0 else 0;
}
