# Lifting kristtst01/codetrace#41 — graph visualization mode:
# general directed/weighted graph with BFS/DFS traversal step generation.

node GNode {
    has nid: str;
    has label: str;
    has x: float = 0.0;
    has y: float = 0.0;
}

edge GEdge {
    has weight: float = 1.0;
}

obj GraphData {
    has directed: bool = False;
    has weighted: bool = False;
    has nodes: dict[str, GNode] = {};
    has order: list[str] = [];
    has seq: int = 0;

    def add_node(label: str, x: float, y: float) -> str {
        self.seq += 1;
        nid: str = "n" + str(self.seq);
        nd = GNode(nid=nid, label=label, x=x, y=y);
        self.nodes[nid] = nd;
        self.order.append(nid);
        return nid;
    }

    def add_edge(from_id: str, to_id: str, weight: float = 1.0) -> bool {
        src = self.nodes.get(from_id);
        dst = self.nodes.get(to_id);
        if src is None or dst is None {
            return False;
        }
        if src +>:GEdge(weight=weight):+> dst {} else {}
        if not self.directed {
            if dst +>:GEdge(weight=weight):+> src {} else {}
        }
        return True;
    }

    def remove_node(nid: str) -> bool {
        if self.nodes.get(nid) is None {
            return False;
        }
        del self.nodes[nid];
        self.order = [o for o in self.order if o != nid];
        return True;
    }

    def remove_edge(from_id: str, to_id: str) -> bool {
        src = self.nodes.get(from_id);
        dst = self.nodes.get(to_id);
        if src is None or dst is None {
            return False;
        }
        for e in [src ->:GEdge:->] {
            if e in [dst <-:GEdge:<-] {
                del e;
            }
        }
        return True;
    }

    def get_neighbors(nid: str) -> list[str] {
        out: list[str] = [];
        nd = self.nodes.get(nid);
        if nd is None {
            return out;
        }
        for ch in [nd ->:GEdge:->][?:GNode] {
            out.append(ch.nid);
        }
        return sorted(out);
    }

    def get_adjacency_list -> dict[str, list[str]] {
        adj: dict[str, list[str]] = {};
        for nid in self.order {
            adj[nid] = self.get_neighbors(nid);
        }
        return adj;
    }
}

def create_complete_graph(n: int) -> GraphData {
    g = GraphData();
    ids: list[str] = [];
    for i in range(n) {
        ids.append(g.add_node("v" + str(i), float(i), 0.0));
    }
    for i in range(n) {
        for j in range(n) {
            if i != j {
                g.add_edge(ids[i], ids[j]);
            }
        }
    }
    return g;
}

walker GraphBfs {
    has start: str;
    has visited: list[str] = [];
    has claimed: dict[str, bool] = {};

    can step with GNode entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        self.visited.append(here.nid);
        kids: list[GNode] = [here ->:GEdge:->][?:GNode];
        visit kids;
    }
}

walker GraphDfs {
    has start: str;
    has visited: list[str] = [];
    has claimed: dict[str, bool] = {};

    can step with GNode entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        self.visited.append(here.nid);
        kids: list[GNode] = [];
        raw: list[GNode] = [here ->:GEdge:->][?:GNode];
        for ch in raw {
            kids.append(ch);
        }
        visit :0: kids;
    }
}

def graph_bfs(g: GraphData, start: str) -> list[str] {
    s = g.nodes.get(start);
    if s is None {
        return [];
    }
    w = s spawn GraphBfs(start=start, claimed={});
    return w.visited;
}

def graph_dfs(g: GraphData, start: str) -> list[str] {
    s = g.nodes.get(start);
    if s is None {
        return [];
    }
    w = s spawn GraphDfs(start=start, claimed={});
    return w.visited;
}

with entry {
    g = create_complete_graph(4);
    print(sorted(g.get_adjacency_list().keys()));
}
