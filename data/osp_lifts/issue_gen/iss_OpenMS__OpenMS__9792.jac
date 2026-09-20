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
