"""ahmed-shahriyar/Competitive_Programing#1 — Graph BFS reachability over adjacency lists."""
import from __future__ { annotations }
import from collections { deque }
class GraphStore {
    def init(self: GraphStore) -> None {
        self._nodes: set[int] = `set();
        self._adj: dict[(int, list[int])] = {};
    }
}
def load_graph(nodes: list[int], edges: list[tuple[(int, int)]]) -> GraphStore {
    g = GraphStore();
    for n in nodes {
        g._nodes.add(n);
        g._adj.setdefault(n, []);
    }
    for (u, v) in edges {
        if ((u in g._nodes) and (v in g._nodes)) {
            g._adj.setdefault(u, []).append(v);
            g._adj.setdefault(v, g._adj.get(v, []));
        }
    }
    return g;
}
def bfs_reachable(g: GraphStore, start: int) -> list[int] {
    if (start not in g._nodes) {
        return [];
    }
    q: deque[int] = deque([start]);
    seen: set[int] = {start};
    order: list[int] = [];
    while q {
        cur = q.popleft();
        order.append(cur);
        for nxt in sorted(g._adj.get(cur, [])) {
            if (nxt not in seen) {
                seen.add(nxt);
                q.append(nxt);
            }
        }
    }
    order.pop(0);
    return sorted(order);
}
def bfs_distance(g: GraphStore, start: int, target: int) -> (int | None) {
    if ((start not in g._nodes) or (target not in g._nodes)) {
        return None;
    }
    if (start == target) {
        return 0;
    }
    q: deque[tuple[(int, int)]] = deque([(start, 0)]);
    seen: set[int] = {start};
    while q {
        (cur, dist) = q.popleft();
        for nxt in sorted(g._adj.get(cur, [])) {
            if (nxt == target) {
                return (dist + 1);
            }
            if (nxt not in seen) {
                seen.add(nxt);
                q.append((nxt, (dist + 1)));
            }
        }
    }
    return None;
}
def out_neighbors(g: GraphStore, node_id: int) -> list[int] {
    if (node_id not in g._nodes) {
        return [];
    }
    return sorted(g._adj.get(node_id, []));
}

