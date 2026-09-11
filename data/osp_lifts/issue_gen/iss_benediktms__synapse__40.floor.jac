"""benediktms/synapse#40 — BFS memory subgraph expansion with node budget.

Hand-rolled adjacency dict + deque frontier walk for graph_subgraph-style
neighbourhood collection with truncation budget.
"""
import from __future__ { annotations }
import from collections { deque }
class MemoryGraph {
    def init(self: MemoryGraph) -> None {
        self.memories: set[str] = `set();
        self.links: dict[(str, list[str])] = {};
    }
}
def load_memory_graph(
    memories: list[str], links: list[tuple[(str, str)]]
) -> MemoryGraph {
    g = MemoryGraph();
    for mid in memories {
        g.memories.add(mid);
        g.links.setdefault(mid, []);
    }
    for (src, dst) in links {
        if ((src in g.memories) and (dst in g.memories)) {
            g.links[src].append(dst);
            g.links.setdefault(dst, g.links.get(dst, []));
        }
    }
    return g;
}
def subgraph_nodes(g: MemoryGraph, seeds: list[str], max_nodes: int) -> list[str] {
    seen: set[str] = `set();
    q: deque[str] = deque();
    for s in seeds {
        if ((s in g.memories) and (s not in seen)) {
            seen.add(s);
            q.append(s);
        }
    }
    while (q and (len(seen) < max_nodes)) {
        cur = q.popleft();
        for nxt in g.links.get(cur, []) {
            if ((nxt not in seen) and (len(seen) < max_nodes)) {
                seen.add(nxt);
                q.append(nxt);
            }
        }
    }
    return sorted(seen);
}
def truncated(g: MemoryGraph, seeds: list[str], max_nodes: int) -> bool {
    full = subgraph_nodes(g, seeds, (len(g.memories) + 1));
    capped = subgraph_nodes(g, seeds, max_nodes);
    return (len(capped) < len(full));
}

