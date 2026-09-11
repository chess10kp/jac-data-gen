"""BharatDBPG/BharatDBMS-PG#3005 — recursive view traversal with level tracking."""

node ViewNode {
    has name: str;
}

edge LinksTo {}

obj ViewGraph {
    has nodes: dict[str, ViewNode] = {};
}

def load_view_graph(nodes: list[str], edges: list[tuple[str, str]]) -> ViewGraph {
    g = ViewGraph();
    for n in nodes {
        nd = ViewNode(name=n);
        root ++> nd;
        g.nodes[n] = nd;
    }
    for (a, b) in edges {
        na = g.nodes.get(a, None);
        nb = g.nodes.get(b, None);
        if na is not None and nb is not None { na +>:LinksTo:+> nb; }
    }
    return g;
}

def reachable_with_levels(store: ViewGraph, start: str) -> dict[str, int] {
    nd = store.nodes.get(start, None);
    if nd is None { return {}; }
    levels: dict[str, int] = {start: 0};
    frontier: list[ViewNode] = [nd];
    while len(frontier) > 0 {
        cur = frontier.pop(0);
        for nxt in [cur ->:LinksTo:->][?:ViewNode] {
            nl = levels[cur.name] + 1;
            if not (nxt.name in levels) or nl < levels[nxt.name] {
                levels[nxt.name] = nl;
                frontier.append(nxt);
            }
        }
    }
    return levels;
}
