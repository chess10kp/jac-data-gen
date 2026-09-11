"""guevara/read-it-later#7154 — adjacency-list hierarchy queries."""

node AdjNode {
    has name: str;
}

edge ChildOf {}

obj AdjHierarchy {
    has nodes: dict[str, AdjNode] = {};
}

walker DescCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with AdjNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        visit [here->:ChildOf:->][?:AdjNode];
    }
}

def load_adjacency(
    nodes: list[tuple[str, str | None]],
) -> AdjHierarchy {
    tree = AdjHierarchy();
    for (name, parent) in nodes {
        if parent is not None and tree.nodes.get(parent, None) is None {
            raise KeyError("unknown parent");
        }
        nd = AdjNode(name=name);
        root ++> nd;
        tree.nodes[name] = nd;
        if parent is not None {
            p = tree.nodes.get(parent, None);
            if p is not None { p +>:ChildOf:+> nd; }
        }
    }
    return tree;
}

def adj_descendants(tree: AdjHierarchy, `root: str) -> list[str] {
    nd = tree.nodes.get(`root, None);
    if nd is None { return []; }
    w = nd spawn DescCollect(claimed={}, found=[]);
    out: list[str] = [];
    for name in w.found {
        if name != `root { out.append(name); }
    }
    return sorted(out);
}

def adj_depth(tree: AdjHierarchy, `node: str) -> int {
    nd = tree.nodes.get(`node, None);
    if nd is None { return -1; }
    depth = 0;
    cur: AdjNode | None = nd;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur.name in seen { return -1; }
        seen[cur.name] = True;
        parent: AdjNode | None = None;
        for p in [cur <-:ChildOf:<-][?:AdjNode] {
            parent = p;
            break;
        }
        if parent is None { break; }
        depth += 1;
        cur = parent;
    }
    return depth;
}

def adj_leaves(tree: AdjHierarchy) -> list[str] {
    out: list[str] = [];
    for name in sorted(tree.nodes.keys()) {
        nd = tree.nodes.get(name, None);
        if nd is None { continue; }
        kids = [nd ->:ChildOf:->][?:AdjNode];
        if len(kids) == 0 { out.append(name); }
    }
    return out;
}
