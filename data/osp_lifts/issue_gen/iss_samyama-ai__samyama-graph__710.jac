"""samyama-ai/samyama-graph#710 — variable-length path endpoint reachability by hop count."""

obj PathGraph { has nodes: dict[str, PathNode] = {}; }
node PathNode { has name: str; }
edge Rel {}

walker ExpandHop {
    has cur_depth: int;
    has next: list[tuple[PathNode, int]] = [];

    can step with PathNode entry {
        for nxt in [here ->:Rel:->][?:PathNode] {
            self.next.append((nxt, self.cur_depth + 1));
        }
    }
}

walker BrokenHop {
    has claimed: dict[str, bool];
    has cur_depth: int;
    has next: list[tuple[PathNode, int]] = [];

    can step with PathNode entry {
        for nxt in [here ->:Rel:->][?:PathNode] {
            if nxt.name in self.claimed { continue; }
            self.next.append((nxt, self.cur_depth + 1));
        }
    }
}

def load_graph(
    nodes: list[str],
    edges: list[tuple[str, str]],
) -> PathGraph {
    g = PathGraph(nodes={});
    for n in nodes {
        p = PathNode(name=n);
        root ++> p;
        g.nodes[n] = p;
    }
    for (src, dst) in edges {
        a = g.nodes.get(src, None);
        b = g.nodes.get(dst, None);
        if a is not None and b is not None { a +>:Rel:+> b; }
    }
    return g;
}

def reachable_by_path_length(
    g: PathGraph,
    start: str,
    min_len: int,
    max_len: int,
) -> list[str] {
    anchor = g.nodes.get(start, None);
    if anchor is None { return []; }
    results: dict[str, bool] = {};
    frontier: list[tuple[PathNode, int]] = [(anchor, 0)];
    depth = 0;
    while len(frontier) > 0 and depth <= max_len {
        nxt: list[tuple[PathNode, int]] = [];
        for (node, d) in frontier {
            w = node spawn ExpandHop(next=nxt, cur_depth=d);
            nxt = w.next;
        }
        depth += 1;
        for (node, d) in nxt {
            if d >= min_len and d <= max_len and node.name != start {
                results[node.name] = True;
            }
        }
        if depth >= max_len { break; }
        frontier = nxt;
    }
    out: list[str] = [];
    for k in results.keys() { out.append(k); }
    return sorted(out);
}

def shortest_only_broken(
    g: PathGraph,
    start: str,
    min_len: int,
    max_len: int,
) -> list[str] {
    anchor = g.nodes.get(start, None);
    if anchor is None { return []; }
    results: dict[str, bool] = {};
    claimed: dict[str, bool] = {start: True};
    frontier: list[tuple[PathNode, int]] = [(anchor, 0)];
    depth = 0;
    while len(frontier) > 0 and depth <= max_len {
        nxt: list[tuple[PathNode, int]] = [];
        for (node, d) in frontier {
            w = node spawn BrokenHop(claimed=claimed, next=nxt, cur_depth=d);
            nxt = w.next;
        }
        depth += 1;
        batch: list[tuple[PathNode, int]] = [];
        for (node, d) in nxt {
            if node.name in claimed { continue; }
            claimed[node.name] = True;
            batch.append((node, d));
            if d >= min_len and d <= max_len and node.name != start {
                results[node.name] = True;
            }
        }
        if depth >= max_len { break; }
        frontier = batch;
    }
    out: list[str] = [];
    for k in results.keys() { out.append(k); }
    return sorted(out);
}
