"""drizzle-team/drizzle-orm#5960 — Migration DAG distinct leaf collection."""

obj MigGraph {
    has nodes: dict[str, Snapshot] = {};
}

node Snapshot { has sid: str; }
edge PrevChild {}

walker LeafCollect {
    has claimed: dict[str, bool] = {};
    has leaves: list[str] = [];

    can step with Snapshot entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        kids = [here ->:PrevChild:->][?:Snapshot];
        if not kids {
            self.leaves.append(here.sid);
        } else {
            visit kids;
        }
    }
}

def load_mig_graph(
    nodes: list[str],
    prev_to_children: dict[str, list[str]],
) -> MigGraph {
    g = MigGraph();
    for nid in nodes {
        if nid not in g.nodes {
            nd = Snapshot(sid=nid);
            root ++> nd;
            g.nodes[nid] = nd;
        }
    }
    for (parent, kids) in prev_to_children.items() {
        p = g.nodes.get(parent, None);
        if p is None { continue; }
        for kid in kids {
            c = g.nodes.get(kid, None);
            if c is not None { p +>:PrevChild:+> c; }
        }
    }
    return g;
}

def collect_leaves(g: MigGraph, start_id: str) -> list[str] {
    anchor = g.nodes.get(start_id, None);
    if anchor is None { return []; }
    w = anchor spawn LeafCollect(claimed={}, leaves=[]);
    return sorted(set(w.leaves));
}

def distinct_leaf_count(g: MigGraph, start_id: str) -> int {
    return len(collect_leaves(g, start_id));
}
