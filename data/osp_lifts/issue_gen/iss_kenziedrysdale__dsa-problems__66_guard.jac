"""kenziedrysdale/dsa-problems#66 - Graph reps and four templates."""

node GNode {
    has cid: str;
    has in_deg: int = 0;
}

edge GEdge {}

obj GraphStore {
    has nodes: dict[str, GNode] = {};
}

obj DsuStore {
    has parent: dict[str, str] = {};
    has rank: dict[str, int] = {};
}

def make_store() -> GraphStore {
    return GraphStore();
}

def make_dsu() -> DsuStore {
    return DsuStore();
}

def add_node(store: GraphStore, cid: str) -> None {
    if cid not in store.nodes {
        nd = GNode(cid=cid);
        store.nodes[cid] = nd;
        root ++> nd;
    }
}

def wire_edge(store: GraphStore, src: str, dst: str, directed: bool) -> None {
    add_node(store, src);
    add_node(store, dst);
    a = store.nodes[src] as GNode;
    b = store.nodes[dst] as GNode;
    a +>:GEdge:+> b;
    if directed {
        b.in_deg += 1;
    } else {
        b +>:GEdge:+> a;
    }
}

def _edge_key(a: str, b: str) -> str {
    if a < b {
        return a + "|" + b;
    }
    return b + "|" + a;
}

def _sorted_neighbors(nd: GNode) -> list[GNode] {
    raw: list[GNode] = [];
    for ch in [nd ->:GEdge:->][?:GNode] {
        raw.append(ch);
    }
    keys: list[str] = [];
    for ch in raw {
        keys.append(ch.cid);
    }
    keys = sorted(keys);
    out: list[GNode] = [];
    for k in keys {
        for ch in raw {
            if ch.cid == k {
                out.append(ch);
                break;
            }
        }
    }
    return out;
}

walker BfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can walk with GNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print("bfs " + here.cid);
        nbrs: list[GNode] = _sorted_neighbors(here);
        visit :1: nbrs else { disengage; }
    }
}

walker DfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can walk with GNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print("dfs " + here.cid);
        nbrs: list[GNode] = _sorted_neighbors(here);
        visit :0: nbrs else { disengage; }
    }
}

def bfs_nodes(store: GraphStore, start: str) -> list[str] {
    if start not in store.nodes {
        return [];
    }
    nd = store.nodes[start] as GNode;
    w = nd spawn BfsWalker(claimed={}, order=[]);
    return w.order;
}

def dfs_nodes(store: GraphStore, start: str) -> list[str] {
    if start not in store.nodes {
        return [];
    }
    nd = store.nodes[start] as GNode;
    w = nd spawn DfsWalker(claimed={}, order=[]);
    return w.order;
}

def connected_labels(store: GraphStore) -> dict[str, int] {
    labels: dict[str, int] = {};
    seen: dict[str, bool] = {};
    starts: list[str] = [];
    for cid in store.nodes {
        starts.append(cid);
    }
    starts = sorted(starts);
    comp_id = 0;
    for start in starts {
        if start in seen {
            continue;
        }
        nd = store.nodes[start] as GNode;
        w = nd spawn BfsWalker(claimed={}, order=[]);
        for cid in w.order {
            labels[cid] = comp_id;
            seen[cid] = True;
        }
        comp_id += 1;
    }
    return labels;
}

def dsu_ensure(dsu: DsuStore, x: str) -> None {
    if x not in dsu.parent {
        dsu.parent[x] = x;
        dsu.rank[x] = 0;
    }
}

def dsu_find(dsu: DsuStore, x: str) -> str {
    dsu_ensure(dsu, x);
    if dsu.parent[x] != x {
        dsu.parent[x] = dsu_find(dsu, dsu.parent[x]);
    }
    return dsu.parent[x];
}

def dsu_union(dsu: DsuStore, a: str, b: str) -> None {
    dsu_ensure(dsu, a);
    dsu_ensure(dsu, b);
    ra = dsu_find(dsu, a);
    rb = dsu_find(dsu, b);
    if ra == rb {
        return;
    }
    if dsu.rank[ra] < dsu.rank[rb] {
        tmp = ra;
        ra = rb;
        rb = tmp;
    }
    dsu.parent[rb] = ra;
    if dsu.rank[ra] == dsu.rank[rb] {
        dsu.rank[ra] += 1;
    }
}

def dsu_component_count(nodes: list[str], edges: list[tuple[str, str]]) -> int {
    dsu = make_dsu();
    for n in nodes {
        dsu_ensure(dsu, n);
    }
    for e in edges {
        dsu_union(dsu, e[0], e[1]);
    }
    roots: dict[str, bool] = {};
    for n in nodes {
        r = dsu_find(dsu, n);
        roots[r] = True;
    }
    cnt = 0;
    for r in roots {
        cnt += 1;
    }
    return cnt;
}

def undirected_has_cycle(store: GraphStore) -> bool {
    dsu = make_dsu();
    seen: dict[str, bool] = {};
    for cid in store.nodes {
        dsu_ensure(dsu, cid);
    }
    for cid in store.nodes {
        nd = store.nodes[cid] as GNode;
        for ch in [nd ->:GEdge:->][?:GNode] {
            ek = _edge_key(cid, ch.cid);
            if ek in seen {
                continue;
            }
            seen[ek] = True;
            if dsu_find(dsu, cid) == dsu_find(dsu, ch.cid) {
                return True;
            }
            dsu_union(dsu, cid, ch.cid);
        }
    }
    return False;
}

def kahn_topo(store: GraphStore) -> list[str] | None {
    indeg: dict[str, int] = {};
    for cid in store.nodes {
        nd = store.nodes[cid] as GNode;
        indeg[cid] = nd.in_deg;
    }
    queue: list[str] = [];
    for cid in store.nodes {
        if indeg[cid] == 0 {
            queue.append(cid);
        }
    }
    queue = sorted(queue);
    out: list[str] = [];
    qi = 0;
    while qi < len(queue) {
        cur = queue[qi];
        qi += 1;
        out.append(cur);
        nd = store.nodes[cur] as GNode;
        nbrs: list[GNode] = [];
        for ch in [nd ->:GEdge:->][?:GNode] {
            nbrs.append(ch);
        }
        nbr_ids: list[str] = [];
        for ch in nbrs {
            nbr_ids.append(ch.cid);
        }
        nbr_ids = sorted(nbr_ids);
        for nid in nbr_ids {
            indeg[nid] -= 1;
            if indeg[nid] == 0 {
                queue.append(nid);
            }
        }
        rem: list[str] = [];
        while qi < len(queue) {
            rem.append(queue[qi]);
            qi += 1;
        }
        queue = sorted(rem);
        qi = 0;
    }
    node_cnt = 0;
    for cid in store.nodes {
        node_cnt += 1;
    }
    if len(out) != node_cnt {
        return None;
    }
    return out;
}

test "diamond_bfs_adversarial" {
    st = make_store();
    wire_edge(st, "A", "B", False);
    wire_edge(st, "A", "C", False);
    wire_edge(st, "B", "D", False);
    wire_edge(st, "C", "D", False);
    assert bfs_nodes(st, "A") == ["A", "B", "C", "D"];
    assert dfs_nodes(st, "A") == ["A", "B", "D", "C"];
}

test "unknown_start_tolerance" {
    st = make_store();
    wire_edge(st, "X", "Y", False);
    assert bfs_nodes(st, "Z") == [];
    assert dfs_nodes(st, "Z") == [];
    assert connected_labels(st) == {"X": 0, "Y": 0};
}

test "kahn_cycle_returns_none" {
    st = make_store();
    wire_edge(st, "A", "B", True);
    wire_edge(st, "B", "C", True);
    wire_edge(st, "C", "A", True);
    assert kahn_topo(st) == None;
}

test "dsu_component_count_split" {
    nodes: list[str] = ["a", "b", "c", "d"];
    edges: list[tuple[str, str]] = [("a", "b"), ("c", "d")];
    assert dsu_component_count(nodes, edges) == 2;
}

test "undirected_triangle_has_cycle" {
    st = make_store();
    wire_edge(st, "1", "2", False);
    wire_edge(st, "2", "3", False);
    wire_edge(st, "3", "1", False);
    assert undirected_has_cycle(st) == True;
}

test "kahn_dag_order" {
    st = make_store();
    wire_edge(st, "A", "B", True);
    wire_edge(st, "A", "C", True);
    wire_edge(st, "B", "D", True);
    wire_edge(st, "C", "D", True);
    assert kahn_topo(st) == ["A", "B", "C", "D"];
}
