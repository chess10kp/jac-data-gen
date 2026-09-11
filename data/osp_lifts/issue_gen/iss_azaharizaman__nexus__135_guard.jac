"""azaharizaman/nexus#135 — backoffice organizational hierarchy."""

node Organization {
    has oid: str;
}

edge ChildOf {}

obj OrgStore {
    has orgs: dict[str, Organization] = {};
}

walker DescCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Organization entry {
        if here.oid in self.claimed { skip; }
        self.claimed[here.oid] = True;
        self.found.append(here.oid);
        visit [here->:ChildOf:->][?:Organization];
    }
}

def load_org_tree(
    orgs: list[tuple[str, str | None]],
) -> OrgStore {
    store = OrgStore();
    for (oid, parent) in orgs {
        if parent is not None and store.orgs.get(parent, None) is None {
            raise KeyError("unknown parent organization");
        }
        nd = Organization(oid=oid);
        root ++> nd;
        store.orgs[oid] = nd;
        if parent is not None {
            p = store.orgs.get(parent, None);
            if p is not None { p +>:ChildOf:+> nd; }
        }
    }
    return store;
}

def ancestors_of(store: OrgStore, org_id: str) -> list[str] {
    nd = store.orgs.get(org_id, None);
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

def descendants_of(store: OrgStore, `root: str) -> list[str] {
    nd = store.orgs.get(`root, None);
    if nd is None { return []; }
    w = nd spawn DescCollect(claimed={}, found=[]);
    out: list[str] = [];
    for oid in w.found {
        if oid != `root { out.append(oid); }
    }
    return sorted(out);
}

def subtree_size(store: OrgStore, `root: str) -> int {
    return len(descendants_of(store, `root));
}

def leaf_orgs(store: OrgStore) -> list[str] {
    out: list[str] = [];
    for oid in sorted(store.orgs.keys()) {
        nd = store.orgs.get(oid, None);
        if nd is None { continue; }
        kids = [nd ->:ChildOf:->][?:Organization];
        if len(kids) == 0 { out.append(oid); }
    }
    return out;
}

test "org hierarchy" {
    store = load_org_tree(
        [("hq", None), ("branch-a", "hq"), ("branch-b", "hq"), ("dept-1", "branch-a"), ("cc-1", "dept-1")],
    );
    assert ancestors_of(store, "cc-1") == ["hq", "branch-a", "dept-1", "cc-1"];
    assert descendants_of(store, "hq") == ["branch-a", "branch-b", "cc-1", "dept-1"];
    assert subtree_size(store, "branch-a") == 2;
    assert leaf_orgs(store) == ["branch-b", "cc-1"];
}
