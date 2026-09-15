"""Shortest cycle containing target node — leetcode-pp/91alg-5-daily-check#71."""

node GNode {
    has nid: int;
    has dist: int = -1;
}

edge GEdge {}

walker DistBfs {
    has start_nid: int;
    has claimed: dict[str, bool] = {};

    can propagate with GNode entry {
        key = str(here.nid);
        if key in self.claimed { skip; }
        self.claimed[key] = True;
        print(f"dist_bfs visit nid={here.nid} dist={here.dist}");

        kids: list[GNode] = [];
        for ch in [here ->:GEdge:->][?:GNode] {
            if ch.dist < 0 {
                ch.dist = here.dist + 1;
                kids.append(ch);
            }
        }
        if kids {
            visit kids;
        } else {
            disengage;
        }
    }
}

def build_nodes(graph_adj: list[list[int]]) -> list[GNode] {
    nodes: list[GNode] = [];
    n = len(graph_adj);
    for i in range(n) {
        nd = GNode(nid=i);
        nodes.append(nd);
    }
    for i in range(n) {
        u = nodes[i];
        row = graph_adj[i];
        for j in range(len(row)) {
            v = int(row[j]);
            if v >= 0 and v < n {
                u +>:GEdge:+> nodes[v];
            }
        }
    }
    return nodes;
}

def shortest_cycle_containing_target(graph: list[list[int]], target: int) -> int {
    n = len(graph);
    if n == 0 {
        return -1;
    }
    if target < 0 or target >= n {
        return -1;
    }
    nodes = build_nodes(graph);
    start = nodes[target];
    start.dist = 0;
    claimed: dict[str, bool] = {};
    w = start spawn DistBfs(start_nid=target, claimed=claimed);

    best: int = -1;
    for u_idx in range(n) {
        u = nodes[u_idx];
        d = u.dist;
        if d < 0 {
            continue;
        }
        for ch in [u ->:GEdge:->][?:GNode] {
            if ch.nid == target {
                cand = d + 1;
                if best == -1 or cand < best {
                    best = cand;
                }
            }
        }
    }
    print(f"shortest_cycle target={target} result={best}");
    return best;
}
