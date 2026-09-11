"""KonBase/konbase#71 -- hierarchical organization queries."""

node Org {
    has oid: str;
}

edge Child {}

obj OrgHierarchy {
    has orgs: dict[str, Org] = {};
}

walker DescWalk {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    can step with Org entry {
        if here.oid in self.claimed { skip; }
        self.claimed[here.oid] = True;
        self.out.append(here.oid);
        visit [->:Child:->][?:Org];
    }
}

walker CycleProbe {
    has path_seen: set[str] = set();
    has found: bool = False;
    can step with Org entry {
        if here.oid in self.path_seen { self.found = True; return; }
        new_seen = self.path_seen | {here.oid};
        for ch in [here ->:Child:->][?:Org] {
            sub = CycleProbe(path_seen=new_seen);
            ch spawn sub;
            if sub.found { self.found = True; return; }
        }
    }
}

def make_hierarchy() -> OrgHierarchy {
    return OrgHierarchy();
}

def add_org(h: OrgHierarchy, org_id: str, parent: str | None) -> None {
    if org_id in h.orgs { raise ValueError("duplicate org"); }
    o = Org(oid=org_id);
    root ++> o;
    h.orgs[org_id] = o;
    if parent is not None {
        if not (parent in h.orgs) {
            po = Org(oid=parent);
            root ++> po;
            h.orgs[parent] = po;
        }
        h.orgs[parent] +>:Child:+> o;
    }
}

def descendants(h: OrgHierarchy, root_id: str) -> list[str] {
    if not (root_id in h.orgs) { return []; }
    w = h.orgs[root_id] spawn DescWalk(claimed={}, out=[]);
    res: list[str] = [];
    for oid in w.out { if oid != root_id { res.append(oid); } }
    return sorted(res);
}

def ancestors(h: OrgHierarchy, leaf: str) -> list[str] {
    if not (leaf in h.orgs) { return []; }
    chain: list[str] = [];
    seen: set[str] = set();
    cur: str | None = leaf;
    while cur is not None {
        # find parent via reverse edge
        found: str | None = None;
        for k in h.orgs {
            for ch in [h.orgs[k] ->:Child:->][?:Org] {
                if ch.oid == cur { found = k; }
            }
        }
        if found is None { break; }
        if found in seen { break; }
        chain.append(found);
        seen.add(found);
        cur = found;
    }
    return chain;
}

def depth_of(h: OrgHierarchy, org_id: str) -> int {
    if not (org_id in h.orgs) { raise KeyError(org_id); }
    d = 0;
    cur: str | None = org_id;
    seen: set[str] = set();
    while True {
        found: str | None = None;
        for k in h.orgs {
            for ch in [h.orgs[k] ->:Child:->][?:Org] {
                if ch.oid == cur { found = k; }
            }
        }
        if found is None { break; }
        if found in seen { raise ValueError("cycle"); }
        seen.add(found);
        d += 1;
        cur = found;
    }
    return d;
}

def has_cycle(h: OrgHierarchy) -> bool {
    for oid in h.orgs {
        w = h.orgs[oid] spawn CycleProbe(path_seen=set(), found=False);
        if w.found { return True; }
    }
    return False;
}

test "descendants and ancestors" {
    h = make_hierarchy();
    add_org(h, "root", None);
    add_org(h, "a", "root");
    add_org(h, "b", "root");
    add_org(h, "c", "a");
    assert descendants(h, "root") == ["a", "b", "c"];
    assert descendants(h, "a") == ["c"];
    assert ancestors(h, "c") == ["a", "root"];
    assert depth_of(h, "c") == 2;
    assert depth_of(h, "root") == 0;
}

test "adversarial order same closure" {
    h = make_hierarchy();
    add_org(h, "root", None);
    add_org(h, "b", "root");
    add_org(h, "a", "root");
    add_org(h, "c", "a");
    h2 = make_hierarchy();
    add_org(h2, "root", None);
    add_org(h2, "a", "root");
    add_org(h2, "b", "root");
    add_org(h2, "c", "a");
    assert descendants(h, "root") == descendants(h2, "root");
}

test "deep chain" {
    h = make_hierarchy();
    add_org(h, "n0", None);
    add_org(h, "n1", "n0");
    add_org(h, "n2", "n1");
    add_org(h, "n3", "n2");
    add_org(h, "n4", "n3");
    assert depth_of(h, "n4") == 4;
}

test "cycle detection" {
    h = make_hierarchy();
    add_org(h, "x", None);
    add_org(h, "y", "x");
    # manually create cycle y->x
    h.orgs["y"] +>:Child:+> h.orgs["x"];
    assert has_cycle(h) == True;
    h2 = make_hierarchy();
    add_org(h2, "x", None);
    add_org(h2, "y", "x");
    assert has_cycle(h2) == False;
}

test "unknown returns empty" {
    h = make_hierarchy();
    add_org(h, "root", None);
    assert descendants(h, "ghost") == [];
    assert ancestors(h, "ghost") == [];
}
