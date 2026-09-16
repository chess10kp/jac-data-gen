# Lift: Stewie-pixel/claude-with-leetcode#177
# Find if Path Exists in Graph (BFS reachability -> OSP walker)

node V {
    has vid: int;
}

edge E {}

walker PathSeeker {
    has target: int = -1;
    has found: bool = False;
    has claimed: dict[int, bool] = {};

    can step with V entry {
        if here.vid in self.claimed {
            skip;
        }
        self.claimed[here.vid] = True;
        if here.vid == self.target {
            self.found = True;
            disengage;
        }
        for nei in [here ->:E:->][?:V] {
            visit nei;
        }
    }
}

# Build an undirected graph of n vertices from an edge list.
def build_graph(n: int, edges: list[list[int]]) -> list[V] {
    verts: list[V] = [];
    for i in range(n) {
        v = V(vid=i);
        root ++> v;
        verts.append(v);
    }
    for pr in edges {
        a = verts[pr[0]];
        b = verts[pr[1]];
        a +>:E:+> b;
        b +>:E:+> a;
    }
    return verts;
}

# Public API: does a path exist between source and destination?
def has_path(n: int, edges: list[list[int]], source: int, destination: int) -> bool {
    if source == destination {
        return True;
    }
    if source < 0 or source >= n or destination < 0 or destination >= n {
        return False;
    }
    verts = build_graph(n, edges);
    wk = verts[source] spawn PathSeeker(target=destination);
    return wk.found;
}
