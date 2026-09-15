"""SharonIV0x86/CinderPeak#374 — BFS/DFS traversal with visitor pattern."""

node Vtx {
    has vid: str;
}

edge Adj {}

walker BfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has visitor: object | None = None;

    can bfs_step with Vtx entry {
        if here.vid in self.claimed {
            skip;
        }
        self.claimed[here.vid] = True;
        self.order.append(here.vid);
        print(self.order);
        if self.visitor {
            cont = self.visitor(here.vid);
            if not cont {
                disengage;
            }
        }
        kids: list[Vtx] = [];
        for ch in [here ->:Adj:->][?:Vtx] {
            kids.append(ch);
        }
        for kid in kids {
            visit [kid];
        }
        if not kids {
            disengage;
        }
    }
}

walker DfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has visitor: object | None = None;

    can dfs_step with Vtx entry {
        if here.vid in self.claimed {
            skip;
        }
        self.claimed[here.vid] = True;
        self.order.append(here.vid);
        print(self.order);
        if self.visitor {
            cont = self.visitor(here.vid);
            if not cont {
                disengage;
            }
        }
        kids: list[Vtx] = [];
        for ch in [here ->:Adj:->][?:Vtx] {
            kids.append(ch);
        }
        for kid in kids {
            visit :0: [kid];
        }
        if not kids {
            disengage;
        }
    }
}

walker ReadyWalker {
    has claimed: dict[str, bool] = {};

    can boot with node entry {
        print("CinderPeak#374 traversal ready");
        disengage;
    }
}

obj Graph {
    has vertices: dict[str, Vtx] = {};
}

def make_graph -> Graph {
    return Graph();
}

def add_vertex(g: Graph, vid: str) -> None {
    if vid in g.vertices {
        return;
    }
    v = Vtx(vid=vid);
    root ++> v;
    g.vertices[vid] = v;
}

def add_edge(g: Graph, src: str, dst: str) -> None {
    if src not in g.vertices {
        return;
    }
    if dst not in g.vertices {
        return;
    }
    a = g.vertices[src];
    b = g.vertices[dst];
    a +>:Adj:+> b;
}

def get_vertex(g: Graph, vid: str) -> Vtx | None {
    if vid in g.vertices {
        return g.vertices[vid];
    }
    return None;
}

def bfs(g: Graph, source: str, visitor: object | None = None) -> None {
    if source not in g.vertices {
        return;
    }
    start = g.vertices[source];
    w = start spawn BfsWalker(claimed={}, order=[], visitor=visitor);
    print(w.order);
}

def dfs(g: Graph, source: str, visitor: object | None = None) -> None {
    if source not in g.vertices {
        return;
    }
    start = g.vertices[source];
    w = start spawn DfsWalker(claimed={}, order=[], visitor=visitor);
    print(w.order);
}

def reachable_from(g: Graph, source: str) -> list[str] {
    acc: list[str] = [];
    def collect(vid: str) -> bool {
        acc.append(vid);
        return True;
    }
    bfs(g, source, collect);
    return acc;
}

with entry {
    root spawn ReadyWalker(claimed={});
}
