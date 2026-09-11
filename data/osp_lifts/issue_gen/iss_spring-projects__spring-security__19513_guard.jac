"""spring-projects/spring-security#19513 — ACL parent ancestry and cycle guard."""

node Acl {
    has aid: str;
}

edge ParentOf {}

obj AclStore {
    has acls: dict[str, Acl] = {};
}

walker AncestorWalk {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];
    has cycle_hit: bool = False;

    can step with Acl entry {
        if here.aid in self.claimed {
            self.cycle_hit = True;
            disengage;
        }
        self.claimed[here.aid] = True;
        self.chain.append(here.aid);
        parents = [here <-:ParentOf:<-][?:Acl];
        if len(parents) == 0 { disengage; }
        visit [parents[0]];
    }
}

def load_acls(acls: list[str], parent_edges: list[tuple[str, str]]) -> AclStore {
    store = AclStore();
    for aid in acls {
        if aid not in store.acls {
            nd = Acl(aid=aid);
            root ++> nd;
            store.acls[aid] = nd;
        }
    }
    for (child, parent) in parent_edges {
        c = store.acls.get(child, None);
        p = store.acls.get(parent, None);
        if c is not None and p is not None { p +>:ParentOf:+> c; }
    }
    return store;
}

def ancestor_ids(store: AclStore, acl_id: str) -> list[str] {
    nd = store.acls.get(acl_id, None);
    if nd is None { return []; }
    w = nd spawn AncestorWalk(claimed={}, chain=[], cycle_hit=False);
    if w.cycle_hit { raise ValueError("parent cycle detected"); }
    out = [a for a in w.chain if a != acl_id];
    return sorted(out);
}

def would_create_cycle(store: AclStore, child_id: str, new_parent_id: str) -> bool {
    if child_id not in store.acls or new_parent_id not in store.acls { return False; }
    if child_id == new_parent_id { return True; }
    try {
        for anc in ancestor_ids(store, new_parent_id) {
            if anc == child_id { return True; }
        }
        if new_parent_id == child_id { return True; }
    } except ValueError {
        return True;
    }
    return False;
}

def set_parent(store: AclStore, child_id: str, parent_id: str | None) {
    if child_id not in store.acls { raise KeyError(child_id); }
    if parent_id is not None and parent_id not in store.acls { raise KeyError(parent_id); }
    if parent_id is not None and would_create_cycle(store, child_id, parent_id) {
        raise ValueError("parent assignment would create cycle");
    }
    child = store.acls[child_id];
    old_parents = [child <-:ParentOf:<-][?:Acl];
    for op in old_parents { op del ->:ParentOf:-> child; }
    if parent_id is not None {
        store.acls[parent_id] +>:ParentOf:+> child;
    }
}

def lookup_ancestors_safe(store: AclStore, acl_id: str) -> list[str] {
    nd = store.acls.get(acl_id, None);
    if nd is None { return []; }
    w = nd spawn AncestorWalk(claimed={}, chain=[], cycle_hit=False);
    if w.cycle_hit { raise ValueError("stored parent cycle"); }
    out = [a for a in w.chain if a != acl_id];
    return sorted(out);
}
test "acl ancestry and cycle guard" {
    store = load_acls(["a", "b", "c", "d"], [("b", "a"), ("c", "b"), ("d", "c")]);
    assert ancestor_ids(store, "d") == ["a", "b", "c"];
    assert lookup_ancestors_safe(store, "d") == ["a", "b", "c"];
    assert would_create_cycle(store, "a", "d") is True;
}

test "stored cycle fails fast" {
    store = load_acls(["x", "y"], [("x", "y"), ("y", "x")]);
    failed = False;
    try {
        _ = lookup_ancestors_safe(store, "x");
    } except ValueError {
        failed = True;
    }
    assert failed;
}
