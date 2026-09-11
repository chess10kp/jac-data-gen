"""Arilas/urbex#22 — bridge neighbor recursion with explicit visited guard."""
glob MAX_STEPS: int = 32;
class ChunkGrid {
    def init(self: ChunkGrid) -> None {
        self._chunks: set[tuple[(int, int)]] = set();
        self._neighbors: dict[(tuple[(int, int)], list[tuple[(int, int)]])] = {};
        self._memo: dict[(tuple[(int, int)], (str | None))] = {};
    }
}
def load_chunks(
    coords: list[tuple[(int, int)]],
    neighbor_edges: list[tuple[(tuple[(int, int)], tuple[(int, int)])]]
) -> ChunkGrid {
    g = ChunkGrid();
    for c in coords {
        g._chunks.add(c);
        g._neighbors.setdefault(c, []);
    }
    for (a, b) in neighbor_edges {
        if ((a in g._chunks) and (b in g._chunks)) {
            g._neighbors.setdefault(a, []).append(b);
            g._neighbors.setdefault(b, g._neighbors.get(b, []));
        }
    }
    return g;
}
def _walk_bridge(
    store: ChunkGrid, start: tuple[(int, int)]
) -> tuple[(list[tuple[(int, int)]], bool)] {
    if (start not in store._chunks) {
        return ([], False);
    }
    if (start in store._memo) {
        return ([start], False);
    }
    chain: list[tuple[(int, int)]] = [];
    seen: set[tuple[(int, int)]] = set();
    stack = [start];
    while stack {
        cur = stack.pop();
        if (cur in seen) {
            return (chain, True);
        }
        if (len(chain) >= MAX_STEPS) {
            return (chain, False);
        }
        seen.add(cur);
        chain.append(cur);
        for n in store._neighbors.get(cur, []) {
            if (((n[1] % 2) != 0) and (len(store._neighbors.get(n, [])) > 0)) {
                continue;
            }
            stack.append(n);
        }
    }
    store._memo[start] = "x";
    return (chain, False);
}
def bridge_chain(
    store: ChunkGrid, chunk: tuple[(int, int)]
) -> list[tuple[(int, int)]] {
    (chain, _) = _walk_bridge(store, chunk);
    return `list(chain);
}
def hit_cycle(store: ChunkGrid, chunk: tuple[(int, int)]) -> bool {
    (_, cyc) = _walk_bridge(store, chunk);
    return cyc;
}

