# iss_Stewie-pixel__claude-with-leetcode__157
# LeetCode 2065: Maximum Path Quality of a Graph
# A walk starts and ends at node 0 within maxTime; maximize the sum of
# values of DISTINCT nodes visited. Backtracking: visit counts tell us
# when a node is first entered (collect value) and left (restore state).

node GNode {
    has nid: int;
    has value: int;
}

edge HasEdge {
    has cost: int;
}

# Build the adjacency graph and run the backtracking exploration.
# Public API mirrors Python: maximalPathQuality(values, edges, maxTime)
def maximalPathQuality(values: list[int], edges: list[tuple], max_time: int) -> int {
    nodes: list[GNode | None] = [];
    i: int = 0;
    for i in range(len(values)) {
        nd = GNode(nid=i, value=values[i]);
        nodes.append(nd);
    }
    for e in edges {
        u: int = e[0];
        v: int = e[1];
        t: int = e[2];
        if u >= 0 and u < len(nodes) and v >= 0 and v < len(nodes) {
            un = nodes[u];
            vn = nodes[v];
            un +>:HasEdge(cost=t):+> vn;
            vn +>:HasEdge(cost=t):+> un;
        }
    }
    w = nodes[0] spawn PathExplorer(max_time=max_time, best=values[0], time_used=0, collected=values[0]);
    return w.best;
}

walker PathExplorer {
    has max_time: int;
    has best: int;
    has time_used: int = 0;
    has collected: int = 0;
    has visit_count: dict[int, int] = {};
    has time_rem: dict[int, int] = {};

    can explore with GNode entry {
        nid: int = here.nid;
        cnt: int = self.visit_count.get(nid, 0);
        self.visit_count[nid] = cnt + 1;
        if cnt == 0 and nid != 0 {
            self.collected = self.collected + here.value;
        }
        if nid == 0 {
            if self.collected > self.best {
                self.best = self.collected;
            }
        }
        kids: list[tuple] = [];
        for e in [here ->:HasEdge:->] {
            kid = e.target;
            wgt: int = e.cost;
            kids.append((kid, wgt));
        }
        for pair in kids {
            kid = pair[0];
            wgt: int = pair[1];
            nt: int = self.time_used + wgt;
            if nt > self.max_time {
                continue;
            }
            self.time_used = nt;
            visit :0: [kid];
            self.time_used = nt - wgt;
        }
        if cnt == 0 and nid != 0 {
            self.collected = self.collected - here.value;
        }
        self.visit_count[nid] = cnt;
        if cnt == 0 {
            disengage;
        }
    }
}

with entry {
    vals: list[int] = [0, 32, 10, 43];
    eds: list[tuple] = [(0, 1, 10), (1, 2, 15), (0, 3, 10)];
    print(maximalPathQuality(vals, eds, 49));
    print(maximalPathQuality([5, 10, 15, 20], [(0, 1, 10), (1, 2, 10), (2, 3, 10)], 30));
}

test "maximal_path_quality_basic" {
    q = maximalPathQuality([0, 32, 10, 43], [(0, 1, 10), (1, 2, 15), (0, 3, 10)], 49);
    assert q == 75;
}

test "backtrack_to_zero_only" {
    q = maximalPathQuality([5, 10, 15, 20], [(0, 1, 10), (1, 2, 10), (2, 3, 10)], 30);
    assert q == 15;
}

test "zero_loop_revisit_updates" {
    q = maximalPathQuality([25, 1, 2], [(0, 1, 10), (1, 0, 10), (0, 2, 10), (2, 0, 10)], 100);
    assert q == 28;
}

test "unknown_node_edges_ignored" {
    q = maximalPathQuality([7, 8], [(0, 99, 5), (0, 1, 10)], 10);
    assert q == 15;
}

test "no_return_within_time" {
    q = maximalPathQuality([100, 100], [(0, 1, 10)], 10);
    assert q == 100;
}

test "empty_edges_stays_at_root" {
    q = maximalPathQuality([42], [], 50);
    assert q == 42;
}
