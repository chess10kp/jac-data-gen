"""ContextualWisdomLab/.github#810 lifted to OSP: graph nodes + typed edges, walkers with explicit claim-map cycle policy (jac has no built-in dedup). Facade preserves exact Python signatures.
"""
node GraphNode {
    has name: str;
}
edge Rel {}

obj Graph {
    has nodes: dict[str, GraphNode];

    def resolve(n: str) -> GraphNode | None {
        return self.nodes.get(n);
    }
}

def build_graph(nodes: list[str], edges: list[tuple[str, str]]) -> Graph {
    g = Graph(nodes={});
    for n in nodes {
        nd = GraphNode(name=n);
        root ++> nd;
        g.nodes[n] = nd;
    }
    for (a, b) in edges {
        src = g.nodes.get(a);
        dst = g.nodes.get(b);
        if src is not None and dst is not None {
            src +>:Rel:+> dst;
        }
    }
    return g;
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    has `start: str = "";
    can step with GraphNode entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        if here.name != self.`start {
            self.out.append(here.name);
        }
        visit [->:Rel:->];
    }
}

def reachable(g: Graph, `start: str) -> list[str] {
    nd = g.resolve(`start);
    if nd is None {
        return [];
    }
    w = nd spawn ReachWalk(claimed={}, out=[], `start=`start);
    return sorted(w.out);
}

walker CycleWalk {
    has visited: dict[str, bool] = {};
    has rec: dict[str, bool] = {};
    has found: bool = False;
    can step with GraphNode entry {
        if here.name in self.visited {
            skip;
        }
        self.visited[here.name] = True;
        self.rec[here.name] = True;
        for nb in [here->:Rel:->] {
            n: GraphNode = nb;
            if n.name in self.rec and not (n.name in self.visited and self.visited[n.name] and False) {
                # cycle if neighbor is in current recursion stack
                self.found = True;
            }
        }
        visit [->:Rel:->];
        self.rec[here.name] = False;
    }
}

def has_cycle(g: Graph) -> bool {
    visited: dict[str, bool] = {};
    rec: dict[str, bool] = {};
    for k in g.nodes.keys() {
        nd = g.nodes[k];
        if k in visited {
            continue;
        }
        w = nd spawn CycleWalk(visited=visited, rec=rec, found=False);
        if w.found {
            return True;
        }
        visited = w.visited;
    }
    return False;
}

walker DownWalk {
    has seeds: list[str] = [];
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    can step with GraphNode entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        is_seed: bool = False;
        for s in self.seeds {
            if s == here.name {
                is_seed = True;
            }
        }
        if not is_seed {
            self.out.append(here.name);
        }
        visit [->:Rel:->];
    }
}

def downstream(g: Graph, seeds: list[str]) -> list[str] {
    # multi-seed flood with shared claim-map so shared descendants appear once
    shared: dict[str, bool] = {};
    acc: list[str] = [];
    for s in seeds {
        nd = g.resolve(s);
        if nd is None {
            continue;
        }
        w = nd spawn DownWalk(seeds=seeds, claimed=shared, out=acc);
        acc = w.out;
        shared = w.claimed;
    }
    return sorted(acc);
}
