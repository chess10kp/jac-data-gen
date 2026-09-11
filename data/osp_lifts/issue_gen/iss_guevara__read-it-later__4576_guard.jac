"""guevara/read-it-later#4576 — candidate + hidden guards."""

obj GraphStore { has stamp: int = 0; }
node Vertex { has name: str; }
edge Arc {}

walker ReachFold {
    has start: str;
    has claimed: dict[str, bool] = {};
    has seen: list[str] = [];
    can begin with Root entry {
        for n in [-->][?:Vertex] {
            if n.name == self.start { visit [n]; }
        }
    }
    can walk with Vertex entry {
        nid = here.name;
        if nid in self.claimed { skip; }
        self.claimed[nid] = True;
        self.seen.append(nid);
        visit [here->:Arc:->][?:Vertex];
    }
}

walker CycleScan {
    has color: dict[str, int] = {};
    has found: list[str] = [];
    can scan with Root entry {
        for n in [-->][?:Vertex] {
            if self.color.get(n.name, 0) == 0 { visit [n]; }
        }
    }
    can dfs with Vertex entry {
        nid = here.name;
        st = self.color.get(nid, 0);
        if st == 2 { skip; }
        if st == 1 { skip; }
        self.color[nid] = 1;
        pending: list[Vertex] = [];
        for tgt in [here->:Arc:->][?:Vertex] {
            tn = tgt.name;
            cst = self.color.get(tn, 0);
            if cst == 1 {
                dup = False;
                for x in self.found { if x == tn { dup = True; } }
                if not dup { self.found.append(tn); }
            } elif cst == 0 { pending.append(tgt); }
        }
        visit pending;
        self.color[nid] = 2;
    }
}

def _wire(nodes: list[str], edges: list[tuple[str, str]]) {
    mp: dict[str, Vertex] = {};
    for nm in nodes {
        if nm not in mp { v = Vertex(name=nm); root ++> v; mp[nm] = v; }
    }
    for (a, b) in edges {
        src = mp.get(a, None);
        dst = mp.get(b, None);
        if src is not None and dst is not None { src +>:Arc:+> dst; }
    }
}

def _vertex(name: str) -> Vertex | None {
    for v in [-->][?:Vertex] { if v.name == name { return v; } }
    return None;
}

def load_graph(nodes: list[str], edges: list[tuple[str, str]]) -> GraphStore {
    _wire(nodes, edges);
    return GraphStore(stamp=1);
}

def reachable_from(g: GraphStore, start: str) -> list[str] {
    _ = g;
    if _vertex(start) is None { return []; }
    w = root spawn ReachFold(start=start, claimed={}, seen=[]);
    return sorted(w.seen);
}

def cycle_nodes(g: GraphStore) -> list[str] {
    _ = g;
    w = root spawn CycleScan(color={}, found=[]);
    return sorted(w.found);
}

test "dag reach and no cycles" {
    g = load_graph(
        ["a", "b", "c", "d", "e"],
        [("a", "b"), ("a", "c"), ("b", "d"), ("c", "d"), ("d", "e")],
    );
    assert reachable_from(g, "a") == ["a", "b", "c", "d", "e"];
    assert cycle_nodes(g) == [];
}

test "diamond reach once per vertex" {
    # Adversarial edge insertion: shared target before deeper branches.
    g = load_graph(
        ["s", "l", "r", "t"],
        [("s", "r"), ("l", "t"), ("s", "l"), ("r", "t")],
    );
    assert reachable_from(g, "s") == ["l", "r", "s", "t"];
    assert cycle_nodes(g) == [];
}

test "cycle back-edge target collected" {
    g = load_graph(
        ["a", "b", "c"],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert reachable_from(g, "a") == ["a", "b", "c"];
    assert cycle_nodes(g) == ["a"];
}

test "self loop marks node" {
    g = load_graph(["solo"], [("solo", "solo")]);
    assert reachable_from(g, "solo") == ["solo"];
    assert cycle_nodes(g) == ["solo"];
}

test "unknown start tolerant" {
    g = load_graph(["only"], []);
    assert reachable_from(g, "missing") == [];
}
