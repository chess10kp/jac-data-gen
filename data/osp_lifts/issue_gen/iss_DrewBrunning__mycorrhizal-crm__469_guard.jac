"""DrewBrunning/mycorrhizal-crm#469 — Multi-hop contact relationship traversal."""

node Contact {
    has cid: str;
    has kind: str;
}

edge Knows {}

obj ContactGraph {
    has contacts: dict[str, Contact] = {};
}

def load_contacts(
    contacts: list[tuple[str, str]],
    edges: list[tuple[str, str]],
) -> ContactGraph {
    g = ContactGraph();
    for (cid, kind) in contacts {
        if cid not in g.contacts {
            nd = Contact(cid=cid, kind=kind);
            root ++> nd;
            g.contacts[cid] = nd;
        }
    }
    for (src, dst) in edges {
        a = g.contacts.get(src, None);
        b = g.contacts.get(dst, None);
        if a is not None and b is not None {
            a +>:Knows:+> b;
            b +>:Knows:+> a;
        }
    }
    return g;
}

def reachable_contacts(g: ContactGraph, start: str, max_hops: int = 3) -> list[str] {
    anchor = g.contacts.get(start, None);
    if anchor is None { return []; }
    claimed: dict[str, bool] = {start: True};
    snap: list[tuple[str, int]] = [(start, 0)];
    reached: list[str] = [];
    i = 0;
    while i < len(snap) {
        (cid, depth) = snap[i];
        i += 1;
        if depth >= max_hops { continue; }
        nd = g.contacts.get(cid, None);
        if nd is None { continue; }
        for nb in [nd ->:Knows:->][?:Contact] {
            if nb.cid not in claimed {
                claimed[nb.cid] = True;
                reached.append(nb.cid);
                snap.append((nb.cid, depth + 1));
            }
        }
    }
    return sorted(reached);
}

def hops_between(g: ContactGraph, start: str, end: str) -> int | None {
    if start not in g.contacts or end not in g.contacts { return None; }
    if start == end { return 0; }
    claimed: dict[str, bool] = {start: True};
    snap: list[tuple[str, int]] = [(start, 0)];
    i = 0;
    while i < len(snap) {
        (cid, depth) = snap[i];
        i += 1;
        nd = g.contacts.get(cid, None);
        if nd is None { continue; }
        for nb in [nd ->:Knows:->][?:Contact] {
            if nb.cid == end { return depth + 1; }
            if nb.cid not in claimed {
                claimed[nb.cid] = True;
                snap.append((nb.cid, depth + 1));
            }
        }
    }
    return None;
}

def hub_contacts(g: ContactGraph, min_degree: int) -> list[str] {
    hits: list[str] = [];
    for cid in sorted(g.contacts.keys()) {
        nd = g.contacts[cid];
        if len([nd ->:Knows:->][?:Contact]) >= min_degree { hits.append(cid); }
    }
    return hits;
}
test "multi-hop contact reach" {
    g = load_contacts(
        [("alice", "person"), ("bob", "person"), ("carol", "person"), ("hub", "org")],
        [("alice", "hub"), ("bob", "hub"), ("carol", "hub"), ("hub", "bob")],
    );
    assert reachable_contacts(g, "alice", 2) == ["bob", "carol", "hub"];
    assert hops_between(g, "alice", "carol") == 2;
    assert hub_contacts(g, 3) == ["hub"];
}
