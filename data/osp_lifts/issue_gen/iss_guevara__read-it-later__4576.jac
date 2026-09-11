"""guevara/read-it-later#4576 — adjacency reach and cycle detection (OSP lift)."""

obj GraphStore {
    has stamp: int = 0;
}

node Vertex {
    has name: str;
}

edge Arc {}

walker ReachFold {
    has start: str;
    has claimed: dict[str, bool] = {};
    has seen: list[str] = [];

    can begin with Root entry {
        for n in [-->][?:Vertex] {
            if n.name == self.start {
                visit [n];
            }
        }
    }

    can walk with Vertex entry {
        nid = here.name;
        if nid in self.claimed {
            skip;
        }
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
            if self.color.get(n.name, 0) == 0 {
                visit [n];
            }
        }
    }

    can dfs with Vertex entry {
        nid = here.name;
        st = self.color.get(nid, 0);
        if st == 2 {
            skip;
        }
        if st == 1 {
            skip;
        }
        self.color[nid] = 1;
        pending: list[Vertex] = [];
        for tgt in [here->:Arc:->][?:Vertex] {
            tn = tgt.name;
            cst = self.color.get(tn, 0);
            if cst == 1 {
                dup = False;
                for x in self.found {
                    if x == tn {
                        dup = True;
                    }
                }
                if not dup {
                    self.found.append(tn);
                }
            } elif cst == 0 {
                pending.append(tgt);
            }
        }
        visit pending;
        self.color[nid] = 2;
    }
}

def _wire(nodes: list[str], edges: list[tuple[str, str]]) {
    mp: dict[str, Vertex] = {};
    for nm in nodes {
        if nm not in mp {
            v = Vertex(name=nm);
            root ++> v;
            mp[nm] = v;
        }
    }
    for (a, b) in edges {
        src = mp.get(a, None);
        dst = mp.get(b, None);
        if src is not None and dst is not None {
            src +>:Arc:+> dst;
        }
    }
}

def _vertex(name: str) -> Vertex | None {
    for v in [-->][?:Vertex] {
        if v.name == name {
            return v;
        }
    }
    return None;
}

def load_graph(nodes: list[str], edges: list[tuple[str, str]]) -> GraphStore {
    _wire(nodes, edges);
    return GraphStore(stamp=1);
}

def reachable_from(g: GraphStore, start: str) -> list[str] {
    _ = g;
    if _vertex(start) is None {
        return [];
    }
    w = root spawn ReachFold(start=start, claimed={}, seen=[]);
    return sorted(w.seen);
}

def cycle_nodes(g: GraphStore) -> list[str] {
    _ = g;
    w = root spawn CycleScan(color={}, found=[]);
    return sorted(w.found);
}
