"""msqd/harp#803 — topological sort O(N+E) (OSP lift)."""

obj TopoGraph { has stamp: int = 0; }
node Vertex { has vid: int; }
edge To {}

def _find(vid: int) -> Vertex | None {
    for v in [-->][?:Vertex] { if v.vid == vid { return v; } }
    return None;
}

def load_graph(edges: list[tuple[int, int]]) -> TopoGraph {
    mp: dict[int, Vertex] = {};
    for (u, v) in edges {
        for vid in [u, v] {
            if vid not in mp { nd = Vertex(vid=vid); root ++> nd; mp[vid] = nd; }
        }
        a = mp.get(u, None); b = mp.get(v, None);
        if a is not None and b is not None { a +>:To:+> b; }
    }
    return TopoGraph(stamp=1);
}

def topological_sort(g: TopoGraph) -> list[int] {
    _ = g;
    indeg: dict[int, int] = {};
    for v in [-->][?:Vertex] { indeg[v.vid] = len([v ->:To:->][?:Vertex]); }
    out: list[int] = [];
    ready = sorted([vid for (vid, d) in indeg.items() if d == 0]);
    while ready {
        out += ready;
        nxt: list[int] = [];
        for vid in ready {
            cur = _find(vid);
            if cur is None { continue; }
            for dep in [cur <-:To:<-][?:Vertex] {
                indeg[dep.vid] -= 1;
                if indeg[dep.vid] == 0 { nxt.append(dep.vid); }
            }
        }
        ready = sorted(nxt);
    }
    return out if len(out) == len(indeg) else [];
}

walker ReachWalk {
    has claimed: dict[int, bool] = {};
    has reached: list[int] = [];
    can step with Vertex entry {
        if here.vid in self.claimed { skip; }
        self.claimed[here.vid] = True;
        self.reached.append(here.vid);
        visit [->:To:->] else { disengage; };
    }
}

def reachable_from(g: TopoGraph, start: int) -> list[int] {
    _ = g;
    anchor = _find(start);
    if anchor is None { return []; }
    w = anchor spawn ReachWalk(claimed={}, reached=[]);
    return sorted(w.reached);
}
