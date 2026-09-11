"""DrewBrunning/mycorrhizal-crm#468 — multi-hop CRM relationship reach."""

node Contact {
    has cid: str;
}

edge RelatedTo {}

obj CrmGraph {
    has contacts: dict[str, Contact] = {};
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has anchor: str = "";

    can step with Contact entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid != self.anchor { self.reached.append(here.cid); }
        visit [->:RelatedTo:->][?:Contact];
    }
}

def load_crm(
    contacts: list[str],
    relation_edges: list[tuple[str, str]],
) -> CrmGraph {
    g = CrmGraph();
    for cid in contacts {
        nd = Contact(cid=cid);
        root ++> nd;
        g.contacts[cid] = nd;
    }
    for (a, b) in relation_edges {
        na = g.contacts.get(a, None);
        nb = g.contacts.get(b, None);
        if na is not None and nb is not None { na +>:RelatedTo:+> nb; }
    }
    return g;
}

def reachable_contacts(store: CrmGraph, start: str) -> list[str] {
    nd = store.contacts.get(start, None);
    if nd is None { return []; }
    w = nd spawn ReachWalk(claimed={}, anchor=start);
    return sorted(w.reached);
}

def relationship_hops(store: CrmGraph, start: str) -> int {
    nd = store.contacts.get(start, None);
    if nd is None { return -1; }
    depth: dict[str, int] = {start: 0};
    frontier: list[Contact] = [nd];
    best = 0;
    while len(frontier) > 0 {
        cur = frontier.pop(0);
        for nxt in [cur ->:RelatedTo:->][?:Contact] {
            nd2 = depth[cur.cid] + 1;
            if nd2 > best { best = nd2; }
            if not (nxt.cid in depth) or nd2 > depth[nxt.cid] {
                depth[nxt.cid] = nd2;
                frontier.append(nxt);
            }
        }
    }
    return best;
}

def hub_neighbors(store: CrmGraph, hub_id: str) -> list[str] {
    nd = store.contacts.get(hub_id, None);
    if nd is None { return []; }
    out: list[str] = [];
    for n in [nd ->:RelatedTo:->][?:Contact] { out.append(n.cid); }
    return sorted(out);
}

test "crm reach linear" {
    g = load_crm(
        ["alice", "bob", "carol", "dave", "eve"],
        [("alice", "bob"), ("bob", "carol"), ("alice", "dave"), ("dave", "eve")],
    );
    assert reachable_contacts(g, "alice") == ["bob", "carol", "dave", "eve"];
    assert relationship_hops(g, "alice") == 2;
}

test "diamond adversarial revisit" {
    g = load_crm(
        ["hub", "a", "b", "tip"],
        [("hub", "a"), ("hub", "b"), ("a", "tip"), ("b", "tip")],
    );
    assert reachable_contacts(g, "hub") == ["a", "b", "tip"];
}
