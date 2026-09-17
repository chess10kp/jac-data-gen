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
