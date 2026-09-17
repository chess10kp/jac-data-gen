node Node {
    has nid: str;
    has name: str;
}

node Graph {
    has gid: str;
}

edge DependsOn {
    has ordinal: int = 0;
}

# Recursive dependency walk mirroring the WITH RECURSIVE ds(id, depth) query:
# follow DependsOn edges forward (dependents), each hop increments depth.
walker GetDependentNodes {
    has start_id: str = "";
    has depths: dict[str, int] = {};
    has claimed: dict[str, bool] = {};
    has depth: int = 0;

    can step with Node entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        self.depths[here.nid] = self.depth;
        kids: list[Node] = [];
        for ch in [here ->:DependsOn:->][?:Node] {
            if ch.nid not in self.claimed {
                kids.append(ch);
            }
        }
        if len(kids) == 0 {
            disengage;
        }
        for p in kids {
            sub = GetDependentNodes(depth=self.depth + 1, depths=self.depths, claimed=self.claimed, start_id=self.start_id);
            p spawn sub;
        }
    }
}

# Reachability probe used to locate a node anywhere in the graph by id.
walker FindNode {
    has target: str;
    has found: list[Node] = [];
    has claimed: dict[str, bool] = {};

    can step with Node entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        if here.nid == self.target {
            self.found.append(here);
        }
        visit [here ->:DependsOn:->] else { disengage; }
    }
}

def build_graph(gid: str, names: list[str]) -> Graph {
    g = Graph(gid=gid);
    root ++> g;
    for nm in names {
        nd = Node(nid=nm, name=nm);
        g +>:DependsOn:+> nd;
    }
    return g;
}

def find_node(g: Graph, nid: str) -> Node | None {
    anchors: list[Node] = [g ->:DependsOn:->][?:Node];
    for nd in anchors {
        if nd.nid == nid {
            return nd;
        }
    }
    probe = FindNode(target=nid);
    for nd in anchors {
        nd spawn probe;
        if len(probe.found) > 0 {
            return probe.found[0];
        }
    }
    return None;
}

def get_dependent_nodes(g: Graph, start_id: str) -> list[tuple[str, int]] {
    rows: list[tuple[str, int]] = [];
    start = find_node(g, start_id);
    if start is None {
        return rows;
    }
    w = GetDependentNodes(start_id=start_id, depth=0);
    start spawn w;
    for nid in w.depths.keys() {
        rows.append((nid, w.depths[nid]));
    }
    out: list[tuple[str, int]] = [];
    for r in sorted(rows) {
        out.append(r);
    }
    return out;
}

def connect(g: Graph, parent_id: str, child_id: str, ordinal: int) -> None {
    p = find_node(g, parent_id);
    c = find_node(g, child_id);
    if p is None {
        return;
    }
    if c is None {
        return;
    }
    e = DependsOn(ordinal=ordinal);
    p +>:e:+> c;
}

test "chain_depths" {
    g = build_graph("g1", ["a", "b", "c"]);
    connect(g, "a", "b", 0);
    connect(g, "b", "c", 0);
    rows = get_dependent_nodes(g, "a");
    assert rows == [("a", 0), ("b", 1), ("c", 2)];
}

test "diamond_adversarial_order" {
    g = build_graph("g2", ["a", "c", "b", "d"]);
    connect(g, "a", "c", 0);
    connect(g, "a", "b", 0);
    connect(g, "c", "d", 0);
    connect(g, "b", "d", 0);
    rows = get_dependent_nodes(g, "a");
    assert rows == [("a", 0), ("b", 1), ("c", 1), ("d", 2)];
}

test "unknown_id_returns_empty" {
    g = build_graph("g3", ["x", "y"]);
    connect(g, "x", "y", 0);
    rows = get_dependent_nodes(g, "zzz");
    assert rows == [];
}

test "cycle_terminates_with_claim_map" {
    g = build_graph("g4", ["a", "b"]);
    connect(g, "a", "b", 0);
    connect(g, "b", "a", 0);
    rows = get_dependent_nodes(g, "a");
    assert rows == [("a", 0), ("b", 1)];
}

test "depth_sorted_by_depth_then_id" {
    g = build_graph("g5", ["a", "z", "m"]);
    connect(g, "a", "z", 0);
    connect(g, "a", "m", 0);
    rows = get_dependent_nodes(g, "a");
    assert rows == [("a", 0), ("m", 1), ("z", 1)];
}

test "connect_finds_deep_nodes" {
    g = build_graph("g6", ["a", "b", "c"]);
    connect(g, "a", "b", 0);
    connect(g, "b", "c", 0);
    rows = get_dependent_nodes(g, "b");
    assert rows == [("b", 0), ("c", 1)];
}
