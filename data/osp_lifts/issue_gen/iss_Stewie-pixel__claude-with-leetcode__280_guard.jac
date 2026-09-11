"""Stewie-pixel/claude-with-leetcode#280 — Network recovery pathways."""

node NetNode {
    has idx: int;
    has online: bool;
}

edge Route {
    has cost: int;
}

obj NetworkStore {
    has n: int;
    has nodes: dict[int, NetNode] = {};
    has weights: dict[str, int] = {};
}

def load_network(
    n: int,
    online: list[bool],
    edges: list[tuple[int, int, int]],
) -> NetworkStore {
    net = NetworkStore(n=n, nodes={});
    for i in range(n) {
        nd = NetNode(idx=i, online=online[i]);
        root ++> nd;
        net.nodes[i] = nd;
    }
    for (u, v, w) in edges {
        a = net.nodes.get(u, None);
        b = net.nodes.get(v, None);
        if a is not None and b is not None {
            a +>:Route(cost=w):+> b;
            net.weights[str(u) + ":" + str(v)] = w;
        }
    }
    return net;
}

def _topo_order(store: NetworkStore) -> list[int] {
    indeg: dict[int, int] = {};
    for i in range(store.n) { indeg[i] = 0; }
    for i in range(store.n) {
        nd = store.nodes[i];
        for nxt in [nd ->:Route:->] {
            nn: NetNode = nxt;
            indeg[nn.idx] = indeg[nn.idx] + 1;
        }
    }
    queue: list[int] = [];
    for i in range(store.n) {
        if indeg[i] == 0 { queue.append(i); }
    }
    order: list[int] = [];
    while len(queue) > 0 {
        u = queue.pop(0);
        order.append(u);
        und = store.nodes[u];
        for nxt in [und ->:Route:->] {
            nn: NetNode = nxt;
            indeg[nn.idx] = indeg[nn.idx] - 1;
            if indeg[nn.idx] == 0 { queue.append(nn.idx); }
        }
    }
    return order;
}

def feasible(store: NetworkStore, threshold: int, budget: int) -> bool {
    order = _topo_order(store);
    if len(order) != store.n { return False; }
    dist: dict[int, int] = {};
    for i in range(store.n) { dist[i] = 1000000000000000000; }
    dist[0] = 0;
    for u in order {
        if dist[u] > budget { continue; }
        und = store.nodes[u];
        for nxt in [und ->:Route:->] {
            nn: NetNode = nxt;
            key = str(u) + ":" + str(nn.idx);
            w = store.weights.get(key, 0);
            if w < threshold { continue; }
            if not nn.online and nn.idx != store.n - 1 { continue; }
            nd = dist[u] + w;
            if nd < dist[nn.idx] { dist[nn.idx] = nd; }
        }
    }
    return dist[store.n - 1] <= budget;
}

def max_min_path(
    n: int,
    online: list[bool],
    edges: list[tuple[int, int, int]],
    budget: int,
) -> int {
    store = load_network(n, online, edges);
    weights: list[int] = [];
    seen: dict[int, bool] = {};
    for (_, _, w) in edges {
        if not (w in seen) {
            seen[w] = True;
            weights.append(w);
        }
    }
    weights = sorted(weights);
    lo = 0;
    hi = len(weights) - 1;
    answer = -1;
    while lo <= hi {
        mid = (lo + hi) // 2;
        if feasible(store, weights[mid], budget) {
            answer = weights[mid];
            lo = mid + 1;
        } else {
            hi = mid - 1;
        }
    }
    return answer;
}

test "max min path binary search" {
    n = 4;
    online = [True, True, True, True];
    edges = [(0, 1, 5), (1, 2, 3), (2, 3, 4), (0, 2, 2)];
    assert max_min_path(n, online, edges, 20) == 3;
    net = load_network(n, online, edges);
    assert feasible(net, 3, 20) is True;
    assert feasible(net, 5, 20) is False;
}
