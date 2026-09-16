# sqlc-dev/sqlc#2390 — recursive depth-walk over tree edges with computed
# integer terms (depth+1), like a recursive CTE whose UNION ALL term computes
# new integers per level. OSP lift: nodes + typed Edge, a walker carries a
# depth field and spawns child walkers at depth+1; a claim-map guards cycles.

node Graph { has name: str; }
node Node {
    has nid: str;
    has kind: str = "generic";
    has name: str = "";
}
edge Edge { has ordinal: int = 0; }

# recursive-CTE analogue: returns list of (nid, depth) rows, sorted by depth
def get_dependent_nodes(start_nid: str, g: Graph | None = None) -> list[tuple[str, int]] {
    src: Graph = root;
    if g is not None {
        src = g;
    }
    start: Node | None = None;
    for nd in [src ->:Edge:->][?:Node] {
        if nd.nid == start_nid { start = nd; }
    }
    rows: list[tuple[str, int]] = [];
    if start is None {
        # unknown id tolerated: empty result, no exception
        return rows;
    }
    wk = start spawn DepWalk(claimed={}, depth=0);
    for r in wk.rows { rows.append(r); }
    rows.sort(key=lambda t: (t[1], t[0]));
    return rows;
}

walker DepWalk {
    has claimed: dict[str, bool] = {};
    has rows: list[tuple[str, int]] = [];
    has depth: int = 0;

    can step with Node entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.rows.append((here.nid, self.depth));
        # collect children; each child becomes a UNION ALL term at depth+1
        kids: list[Node] = [];
        for ch in [here ->:Edge:->][?:Node] {
            kids.append(ch);
        }
        for kd in kids {
            sub = kd spawn DepWalk(claimed=self.claimed, depth=self.depth + 1);
            for r in sub.rows { self.rows.append(r); }
            for k in sub.claimed.keys() { self.claimed[k] = True; }
        }
        disengage;
    }
}

test "linear chain depths" {
    g = Graph(name="t");
    a = Node(nid="a"); b = Node(nid="b"); c = Node(nid="c");
    g ++> a; g ++> b; g ++> c;
    a +>:Edge:+> b; b +>:Edge:+> c;
    rows = get_dependent_nodes("a", g);
    assert rows == [("a",0), ("b",1), ("c",2)];
}

test "diamond adversarial order" {
    g = Graph(name="t2");
    a = Node(nid="a"); b = Node(nid="b"); c = Node(nid="c"); d = Node(nid="d");
    g ++> a; g ++> b; g ++> c; g ++> d;
    # b (earlier-sorted) reaches d first; c must still report d at depth 2 max
    a +>:Edge:+> b; a +>:Edge:+> c; b +>:Edge:+> d; c +>:Edge:+> d;
    rows = get_dependent_nodes("a", g);
    assert rows == [("a",0), ("b",1), ("c",1), ("d",2)];
}

test "cycle terminates via claim map" {
    g = Graph(name="t3");
    a = Node(nid="a"); b = Node(nid="b"); c = Node(nid="c");
    g ++> a; g ++> b; g ++> c;
    a +>:Edge:+> b; b +>:Edge:+> c; c +>:Edge:+> a;
    rows = get_dependent_nodes("a", g);
    assert rows == [("a",0), ("b",1), ("c",2)];
}

test "unknown id tolerated with empty result" {
    g = Graph(name="t4");
    a = Node(nid="a");
    g ++> a;
    rows = get_dependent_nodes("zzz", g);
    assert rows == [];
}

test "leaf start returns single row" {
    g = Graph(name="t5");
    a = Node(nid="a"); b = Node(nid="b");
    g ++> a; g ++> b;
    a +>:Edge:+> b;
    rows = get_dependent_nodes("b", g);
    assert rows == [("b",0)];
}
