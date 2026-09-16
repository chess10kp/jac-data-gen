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

test "direct_edge_and_two_hop" {
    assert has_path(3, [[0, 1], [1, 2]], 0, 2) == True;
    assert has_path(3, [[0, 1], [1, 2]], 2, 0) == True;
    assert has_path(3, [[0, 1], [1, 2]], 0, 0) == True;
}

test "disconnected_components" {
    assert has_path(6, [[0, 1], [3, 4], [4, 5]], 0, 5) == False;
    assert has_path(6, [[0, 1], [3, 4], [4, 5]], 3, 5) == True;
}

test "diamond_revisit_adversarial" {
    # 0 -> {1, 2}, both 1 and 2 -> 3; late-discovered back edge 3 -> 0
    assert has_path(4, [[0, 1], [0, 2], [1, 3], [2, 3], [3, 0]], 0, 3) == True;
}

test "cycle_heavy_graph" {
    # full cycle plus chord; destination is source's neighbor twice removed
    assert has_path(5, [[0, 1], [1, 2], [2, 3], [3, 4], [4, 0], [0, 2]], 1, 4) == True;
}

test "unknown_id_tolerance" {
    assert has_path(3, [[0, 1]], 0, 7) == False;
    assert has_path(3, [[0, 1]], -1, 1) == False;
    assert has_path(0, [], 0, 0) == True;
}

test "isolated_vertex_single_node" {
    assert has_path(1, [], 0, 0) == True;
    assert has_path(2, [], 0, 1) == False;
}
