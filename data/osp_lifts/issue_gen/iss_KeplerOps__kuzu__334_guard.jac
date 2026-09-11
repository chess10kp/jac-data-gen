"""KeplerOps/kuzu#334 -- attribute-hop recursive query."""

node N {
    has nid: str;
    has typ: str;
}

edge Rel {}

obj Graph {
    has nodes: dict[str, N] = {};
}

walker KHop {
    has claimed: dict[str, bool] = {};
    has cur: set[str] = set();
    has steps: int = 0;
    has target: int = 2;
    can step with N entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.cur.add(here.nid);
        if self.steps < self.target {
            # we handle hops iteratively outside walker; this walker just collects adjacency via visit
            visit [->:Rel:->][?:N];
        }
    }
}

walker ReverseReach {
    has claimed: dict[str, bool] = {};
    has out: set[str] = set();
    has depth: int = 0;
    has src_type: str = "C";
    can step with N entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        if here.typ == self.src_type and self.depth > 0 { self.out.add(here.nid); }
        if self.depth < 6 {
            # reverse walk: need to find predecessors via incoming edges
            # scan all nodes for edge to here
            for p in [<-:Rel:<-][?:N] {
                w = p spawn ReverseReach(claimed=self.claimed, out=self.out, depth=self.depth + 1, src_type=self.src_type);
                for o in w.out { self.out.add(o); }
                for k in w.claimed { self.claimed[k] = True; }
            }
        }
    }
}

walker CycleProbe {
    has path_seen: set[str] = set();
    has found: bool = False;
    can step with N entry {
        if here.nid in self.path_seen { self.found = True; return; }
        new_seen = self.path_seen | {here.nid};
        for ch in [here ->:Rel:->][?:N] {
            sub = CycleProbe(path_seen=new_seen);
            ch spawn sub;
            if sub.found { self.found = True; return; }
        }
    }
}

def make_graph() -> Graph {
    return Graph();
}

def add_node(g: Graph, nid: str, typ: str) -> None {
    if nid in g.nodes { raise ValueError("duplicate node"); }
    n = N(nid=nid, typ=typ);
    root ++> n;
    g.nodes[nid] = n;
}

def add_edge(g: Graph, src: str, dst: str) -> None {
    if not (src in g.nodes) or not (dst in g.nodes) { raise KeyError("unknown node"); }
    g.nodes[src] +>:Rel:+> g.nodes[dst];
}

def k_hop_reachable(g: Graph, start: str, k: int) -> set[str] {
    if not (start in g.nodes) { return set(); }
    cur: set[str] = set();
    cur.add(start);
    for _ in range(k) {
        nxt: set[str] = set();
        for nid in cur {
            if nid in g.nodes {
                for nb in [g.nodes[nid] ->:Rel:->][?:N] { nxt.add(nb.nid); }
            }
        }
        cur = nxt;
        if cur.__len__() == 0 { break; }
    }
    return cur;
}

def count_via_attribute_chain(g: Graph, a_nodes: list[str]) -> int {
    cnt = 0;
    for a in a_nodes {
        if not (a in g.nodes) { continue; }
        if g.nodes[a].typ != "A" { continue; }
        for attr in [g.nodes[a] ->:Rel:->][?:N] {
            if attr.typ != "Attribute" { continue; }
            for c in [attr ->:Rel:->][?:N] {
                if c.typ == "C" { cnt += 1; }
            }
        }
    }
    return cnt;
}

def count_via_recursive(g: Graph, a_nodes: list[str]) -> int {
    cnt = 0;
    for a in a_nodes {
        reached = k_hop_reachable(g, a, 2);
        for r in reached {
            if r in g.nodes and g.nodes[r].typ == "C" { cnt += 1; }
        }
    }
    return cnt;
}

def shortest_hops(g: Graph, target: str, source_type: str) -> set[str] {
    if not (target in g.nodes) { return set(); }
    # BFS reverse limited to 6 hops using queue-like iteration over frontier sets
    seen: set[str] = set();
    seen.add(target);
    frontier: set[str] = set();
    frontier.add(target);
    out: set[str] = set();
    for d in range(6) {
        nxt: set[str] = set();
        for cur in frontier {
            for pred in [g.nodes[cur] <-:Rel:<-][?:N] {
                if not (pred.nid in seen) {
                    seen.add(pred.nid);
                    nxt.add(pred.nid);
                    if pred.typ == source_type { out.add(pred.nid); }
                } else {
                    if pred.typ == source_type { out.add(pred.nid); }
                }
            }
        }
        frontier = nxt;
        if frontier.__len__() == 0 { break; }
    }
    return out;
}

def has_cycle(g: Graph) -> bool {
    for nid in g.nodes {
        w = g.nodes[nid] spawn CycleProbe(path_seen=set(), found=False);
        if w.found { return True; }
    }
    return False;
}

test "attribute vs recursive counts agree" {
    g = make_graph();
    add_node(g, "a1", "A");
    add_node(g, "attr1", "Attribute");
    add_node(g, "c1", "C");
    add_edge(g, "a1", "attr1");
    add_edge(g, "attr1", "c1");
    assert count_via_attribute_chain(g, ["a1"]) == 1;
    assert count_via_recursive(g, ["a1"]) == 1;
    assert k_hop_reachable(g, "a1", 1) == {"attr1"};
    assert k_hop_reachable(g, "a1", 2) == {"c1"};
}

test "order independent" {
    g = make_graph();
    add_node(g, "a1", "A");
    add_node(g, "attr1", "Attribute");
    add_node(g, "c1", "C");
    add_edge(g, "a1", "attr1");
    add_edge(g, "attr1", "c1");
    g2 = make_graph();
    add_node(g2, "c1", "C");
    add_node(g2, "a1", "A");
    add_node(g2, "attr1", "Attribute");
    add_edge(g2, "a1", "attr1");
    add_edge(g2, "attr1", "c1");
    assert count_via_recursive(g2, ["a1"]) == count_via_recursive(g, ["a1"]);
}

test "shortest hops" {
    g = make_graph();
    add_node(g, "a1", "A");
    add_node(g, "attr1", "Attribute");
    add_node(g, "c1", "C");
    add_node(g, "c2", "C");
    add_node(g, "kuzu", "C");
    add_edge(g, "a1", "attr1");
    add_edge(g, "attr1", "c1");
    add_edge(g, "c1", "c2");
    add_edge(g, "c2", "kuzu");
    reach = shortest_hops(g, "kuzu", "C");
    assert "c1" in reach or "c2" in reach;
}

test "cycle detection" {
    g = make_graph();
    add_node(g, "x", "A");
    add_node(g, "y", "Attribute");
    add_edge(g, "x", "y");
    add_edge(g, "y", "x");
    assert has_cycle(g) == True;
    g2 = make_graph();
    add_node(g2, "x", "A");
    add_node(g2, "y", "Attribute");
    add_edge(g2, "x", "y");
    assert has_cycle(g2) == False;
}

test "missing returns empty" {
    g = make_graph();
    add_node(g, "a", "A");
    assert k_hop_reachable(g, "ghost", 2) == set();
}
