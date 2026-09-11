"""markmhendrickson/neotoma#1969 — candidate + hidden guards."""

glob MAX_PATH_DEPTH: int = 4;

obj GraphStore {
    has contacts: dict[str, Contact] = {};
    has companies: dict[str, Company] = {};
    has funds: dict[str, Fund] = {};
    has stamp: int = 0;

    def contact(id: str) -> Contact | None {
        return self.contacts.get(id, None);
    }
}

node Contact { has id: str; }
node Company { has id: str; }
node Fund { has id: str; }
edge Knows {}
edge WorksAt {}
edge InvestedIn {}

walker PathFinder {
    has target_set: dict[str, bool] = {};
    has path: list[str] = [];
    has hops_left: int = 0;
    has results: list[list[str]] = [];

    can step with Contact entry {
        if here.id in self.path { skip; }
        new_path = self.path + [here.id];
        if here.id in self.target_set {
            self.results.append(new_path);
        }
        if self.hops_left <= 0 { disengage; }
        for nb in [here ->:Knows:->][?:Contact] {
            nb spawn PathFinder(
                target_set=self.target_set,
                path=new_path,
                hops_left=self.hops_left - 1,
                results=self.results,
            );
        }
        disengage;
    }
}

def _contacts_at_target(g: GraphStore, target_id: str) -> list[str] {
    if target_id in g.companies {
        out: list[str] = [];
        for (_cid, c) in g.contacts.items() {
            for co in [c ->:WorksAt:->][?:Company] {
                if co.id == target_id { out.append(c.id); break; }
            }
        }
        return sorted(out);
    }
    if target_id in g.funds {
        fund = g.funds[target_id];
        portfolio: dict[str, bool] = {};
        for co in [fund ->:InvestedIn:->][?:Company] {
            portfolio[co.id] = True;
        }
        out2: list[str] = [];
        for (_cid, c) in g.contacts.items() {
            for co in [c ->:WorksAt:->][?:Company] {
                if co.id in portfolio { out2.append(c.id); break; }
            }
        }
        return sorted(out2);
    }
    return [];
}

def load_graph(
    entities: list[tuple[str, str]],
    knows: list[tuple[str, str]],
    works_at: list[tuple[str, str]],
    invested_in: list[tuple[str, str]],
) -> GraphStore {
    g = GraphStore(stamp=1);
    for (eid, kind) in entities {
        if kind == "contact" {
            c = Contact(id=eid);
            root ++> c;
            g.contacts[eid] = c;
        } elif kind == "company" {
            co = Company(id=eid);
            root ++> co;
            g.companies[eid] = co;
        } elif kind == "fund" {
            f = Fund(id=eid);
            root ++> f;
            g.funds[eid] = f;
        }
    }
    for (a, b) in knows {
        ca = g.contact(a);
        cb = g.contact(b);
        if ca is not None and cb is not None { ca +>:Knows:+> cb; }
    }
    for (cid, coid) in works_at {
        c_opt = g.contact(cid);
        co_opt = g.companies.get(coid, None);
        if c_opt is not None and co_opt is not None { c_opt +>:WorksAt:+> co_opt; }
    }
    for (fid, coid) in invested_in {
        f_opt = g.funds.get(fid, None);
        co_opt = g.companies.get(coid, None);
        if f_opt is not None and co_opt is not None { f_opt +>:InvestedIn:+> co_opt; }
    }
    return g;
}

def knows_of(g: GraphStore, contact_id: str) -> list[str] {
    c = g.contact(contact_id);
    if c is None { return []; }
    return sorted([n.id for n in [c ->:Knows:->][?:Contact]]);
}

def find_paths(
    g: GraphStore,
    start: str,
    target_id: str,
    max_depth: int = MAX_PATH_DEPTH,
) -> list[list[str]] {
    anchor = g.contact(start);
    if anchor is None { return []; }
    targets = _contacts_at_target(g, target_id);
    if not targets { return []; }
    tset: dict[str, bool] = {};
    for t in targets { tset[t] = True; }
    w = anchor spawn PathFinder(
        target_set=tset,
        path=[],
        hops_left=max_depth,
        results=[],
    );
    return sorted(w.results);
}

def _fixture() -> GraphStore {
    return load_graph(
        [
            ("alice", "contact"), ("bob", "contact"), ("carol", "contact"),
            ("dana", "contact"), ("eric", "contact"),
            ("acme", "company"), ("beta", "company"), ("sequoia", "fund"),
        ],
        [("alice", "bob"), ("bob", "carol"), ("alice", "dana"), ("carol", "eric")],
        [("carol", "acme"), ("dana", "acme"), ("eric", "beta")],
        [("sequoia", "beta")],
    );
}

test "knows_of and warm paths to company and fund" {
    g = _fixture();
    assert knows_of(g, "alice") == ["bob", "dana"];
    assert find_paths(g, "alice", "acme") == [
        ["alice", "bob", "carol"],
        ["alice", "dana"],
    ];
    assert find_paths(g, "alice", "sequoia") == [
        ["alice", "bob", "carol", "eric"],
    ];
    assert find_paths(g, "dana", "acme") == [["dana"]];
}

test "unknown ids tolerate empty results" {
    g = _fixture();
    assert knows_of(g, "ghost") == [];
    assert find_paths(g, "ghost", "acme") == [];
    assert find_paths(g, "alice", "ghost") == [];
}

test "adversarial-order diamond path enumeration" {
    g = load_graph(
        [
            ("s", "contact"), ("m1", "contact"), ("m2", "contact"),
            ("t", "contact"), ("co", "company"),
        ],
        [("s", "m2"), ("m2", "t"), ("s", "m1"), ("m1", "t"), ("m2", "m1")],
        [("t", "co")],
        [],
    );
    assert find_paths(g, "s", "co") == [
        ["s", "m1", "t"],
        ["s", "m2", "m1", "t"],
        ["s", "m2", "t"],
    ];
}

test "cyclic knows walk terminates" {
    g = load_graph(
        [("a", "contact"), ("b", "contact"), ("c", "contact"), ("co", "company")],
        [("a", "b"), ("b", "c"), ("c", "a")],
        [("c", "co")],
        [],
    );
    assert find_paths(g, "a", "co", max_depth=10) == [["a", "b", "c"]];
}
