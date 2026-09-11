"""nearbytes/nearbytes-files#2 — Materialized directory parent-child tree."""

node DirNode {
    has name: str;
}

edge ChildOf {}

obj DirStore {
    has nodes: dict[str, DirNode] = {};
}

walker SubtreeWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with DirNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        visit [->:ChildOf:->][?:DirNode];
    }
}

def load_directory_tree(segments: list[list[str]]) -> DirStore {
    store = DirStore();
    for parts in segments {
        parent_id: str | None = None;
        for seg in parts {
            if seg not in store.nodes {
                nd = DirNode(name=seg);
                root ++> nd;
                store.nodes[seg] = nd;
                if parent_id is not None and parent_id in store.nodes {
                    par = store.nodes[parent_id];
                    par +>:ChildOf:+> nd;
                }
            }
            parent_id = seg;
        }
    }
    return store;
}

def breadcrumb(store: DirStore, node_id: str) -> list[str] {
    if node_id not in store.nodes { return []; }
    chain: list[str] = [];
    cur: DirNode | None = store.nodes[node_id];
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur.name in seen { break; }
        seen[cur.name] = True;
        chain.append(cur.name);
        parents = [cur <-:ChildOf:<-][?:DirNode];
        cur = parents[0] if len(parents) > 0 else None;
    }
    chain.reverse();
    return chain;
}

def subtree_ids(store: DirStore, root_id: str) -> list[str] {
    start = store.nodes.get(root_id, None);
    if start is None { return []; }
    w = start spawn SubtreeWalk(claimed={}, found=[]);
    return sorted(w.found);
}
