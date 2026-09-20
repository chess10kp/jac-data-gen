"""OpenMS/OpenMS#9792 — pyOpenMS ownership policy audit and alias cascade invalidation."""

node Binding {
    has bid: str;
    has policy: str;
    has alive: bool = True;
}

node Anchor {
    has store_ref: BindingStore;
}

node BindingStore {
    has nodes: dict[str, Binding] = {};
    has anchor: Anchor;
}

edge Alias {}
edge Own {}


def _ends_view(bid: str) -> bool {
    suffix = "_view";
    if len(bid) < len(suffix) {
        return False;
    }
    start = len(bid) - len(suffix);
    tail = bid[start:];
    return tail == suffix;
}


def make_store -> BindingStore {
    st = BindingStore();
    empty: dict[str, Binding] = {};
    st.nodes = empty;
    anc = Anchor();
    st.anchor = anc;
    anc.store_ref = st;
    root ++> anc;
    return st;
}


def register_binding(st: BindingStore, bid: str, policy: str) -> None {
    hit = st.nodes.get(bid);
    if hit {
        hit.policy = policy;
        return;
    }
    nd = Binding(bid=bid, policy=policy, alive=True);
    st.nodes[bid] = nd;
    st.anchor +>:Own:+> nd;
}


def link_owned(st: BindingStore, parent: str, child: str) {
    par = st.nodes.get(parent);
    ch = st.nodes.get(child);
    if par and ch {
        par +>:Own:+> ch;
    }
}


def link_alias(st: BindingStore, parent: str, child: str) {
    par = st.nodes.get(parent);
    ch = st.nodes.get(child);
    if par and ch {
        par +>:Alias:+> ch;
    }
}


walker AuditWalker {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can begin with Anchor entry {
        seeds: list[Binding] = [];
        keys: list[str] = [];
        for bid in st.nodes {
            keys.append(bid);
        }
        keys = sorted(keys);
        for bid in keys {
            nd = here.store_ref.nodes[bid];
            seeds.append(nd);
        }
        visit :0: seeds;
        print {"audit_begin": len(seeds)};
    }

    can probe with Binding entry {
        if here.bid in self.claimed {
            skip;
        }
        self.claimed[here.bid] = True;
        if here.policy == "alias" {
            if not _ends_view(here.bid) {
                self.hits.append(here.bid);
            }
        }
        kids: list[Binding] = [];
        for ch in [here ->:Alias:->][?:Binding] {
            kids.append(ch);
        }
        for ch in [here ->:Own:->][?:Binding] {
            kids.append(ch);
        }
        visit :0: kids else {
            disengage;
        }
        print {"audit_probe": here.bid};
    }
}


def audit_violations(st: BindingStore) -> list[str] {
    w = root spawn AuditWalker(claimed={}, hits=[]);
    out: list[str] = [];
    for x in w.hits {
        out.append(x);
    }
    return sorted(out);
}


walker CollectInvalidateWalker {
    has claimed: dict[str, bool] = {};
    has touched: list[str] = [];
    has seed: str = "";
    has store_ref: BindingStore;

    can begin with Anchor entry {
        self.store_ref = here.store_ref;
        target = self.store_ref.nodes.get(self.seed);
        if target {
            visit [target];
        } else {
            disengage;
        }
        print {"inv_begin": self.seed};
    }

    can probe with Binding entry {
        if here.bid in self.claimed {
            skip;
        }
        self.claimed[here.bid] = True;
        if here.bid != self.seed {
            self.touched.append(here.bid);
        }
        kids: list[Binding] = [];
        for ch in [here ->:Alias:->][?:Binding] {
            kids.append(ch);
        }
        visit :0: kids else {
            disengage;
        }
        print {"inv_probe": here.bid};
    }
}


def invalidate_cascade(st: BindingStore, parent_id: str) -> list[str] {
    par = st.nodes.get(parent_id);
    if not par {
        return [];
    }
    w = root spawn CollectInvalidateWalker(claimed={}, touched=[], seed=parent_id);
    ids: list[str] = [];
    for bid in w.touched {
        ids.append(bid);
    }
    for bid in ids {
        nd = st.nodes[bid];
        if nd {
            nd.alive = False;
        }
    }
    return sorted(ids);
}


def access_mode(st: BindingStore, bid: str) -> str {
    nd = st.nodes.get(bid);
    if not nd {
        return "missing";
    }
    if not nd.alive {
        return "invalid";
    }
    if nd.policy == "alias" {
        return "view";
    }
    return "copy";
}

test "access_mode_missing" {
    st = make_store();
    assert (access_mode(st, "nope") == "missing");;
}

test "access_mode_copy_and_view" {
    st = make_store();
    register_binding(st, "owned", "copy");
    register_binding(st, "alias_view", "alias");
    assert (access_mode(st, "owned") == "copy");;
    assert (access_mode(st, "alias_view") == "view");;
}

test "audit_flags_alias_without_view_suffix" {
    st = make_store();
    register_binding(st, "bad_alias", "alias");
    register_binding(st, "good_view", "alias");
    register_binding(st, "owned", "copy");
    hits = audit_violations(st);
    assert (hits == ["bad_alias"]);;
}

test "invalidate_cascade_via_alias_edges" {
    st = make_store();
    register_binding(st, "parent", "copy");
    register_binding(st, "child_a", "alias");
    register_binding(st, "child_b", "copy");
    link_alias(st, "parent", "child_a");
    link_alias(st, "parent", "child_b");
    touched = invalidate_cascade(st, "parent");
    assert (touched == ["child_a", "child_b"]);;
    assert (access_mode(st, "parent") == "copy");;
    assert (access_mode(st, "child_a") == "invalid");;
    assert (access_mode(st, "child_b") == "invalid");;
}

test "invalidate_unknown_parent_empty" {
    st = make_store();
    register_binding(st, "only", "copy");
    assert (invalidate_cascade(st, "ghost") == []);;
    assert (access_mode(st, "only") == "copy");;
}

test "owned_edges_not_audited_as_violations" {
    st = make_store();
    register_binding(st, "p", "copy");
    register_binding(st, "c", "alias");
    link_owned(st, "p", "c");
    assert (audit_violations(st) == ["c"]);;
}
