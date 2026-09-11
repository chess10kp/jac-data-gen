"""benediktms/synapse#40 — BFS memory subgraph expansion with node budget."""

obj MemoryGraph {
    has memories: dict[str, Memory] = {};
}

node Memory {
    has mid: str;
}

edge LinksTo {}

def load_memory_graph(
    memories: list[str],
    links: list[tuple[str, str]],
) -> MemoryGraph {
    g = MemoryGraph();
    for mid in memories {
        if mid not in g.memories {
            nd = Memory(mid=mid);
            root ++> nd;
            g.memories[mid] = nd;
        }
    }
    for (src, dst) in links {
        a = g.memories.get(src, None);
        b = g.memories.get(dst, None);
        if a is not None and b is not None { a +>:LinksTo:+> b; }
    }
    return g;
}

def subgraph_nodes(g: MemoryGraph, seeds: list[str], max_nodes: int) -> list[str] {
    seen: dict[str, bool] = {};
    reached: list[str] = [];
    snap: list[str] = [];
    for s in seeds {
        if s not in seen { snap.append(s); }
    }
    i = 0;
    while i < len(snap) and len(reached) < max_nodes {
        mid = snap[i];
        i += 1;
        if mid in seen { continue; }
        if mid not in g.memories { continue; }
        seen[mid] = True;
        reached.append(mid);
        if len(reached) >= max_nodes { break; }
        anchor = g.memories.get(mid, None);
        if anchor is None { continue; }
        for nxt in [anchor ->:LinksTo:->][?:Memory] {
            if nxt.mid not in seen and len(reached) < max_nodes {
                snap.append(nxt.mid);
            }
        }
    }
    return sorted(reached);
}

def truncated(g: MemoryGraph, seeds: list[str], max_nodes: int) -> bool {
    full = subgraph_nodes(g, seeds, len(g.memories) + 1);
    capped = subgraph_nodes(g, seeds, max_nodes);
    return len(capped) < len(full);
}
