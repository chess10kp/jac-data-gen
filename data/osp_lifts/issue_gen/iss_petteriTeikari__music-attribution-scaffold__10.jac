"""petteriTeikari/music-attribution-scaffold#10 — GraphStore multi-hop neighbor walk."""

node Entity { has eid: str; }
edge LinksTo {}

obj EdgeGraph {
    has entities: dict[str, Entity] = {};
}

walker HopFrontier {
    has depth: int = 0;
    has max_depth: int = 1;
    has claimed: dict[str, bool] = {};
    has frontier: list[str] = [];

    can step with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        if self.depth == self.max_depth {
            self.frontier.append(here.eid);
            disengage;
        }
        self.depth += 1;
        visit [->:LinksTo:->][?:Entity];
    }
}

walker ReachCollect {
    has max_hops: int = 3;
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has depth: int = 0;

    can step with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        if self.depth > 0 { self.reached.append(here.eid); }
        if self.depth >= self.max_hops { disengage; }
        self.depth += 1;
        visit [->:LinksTo:->][?:Entity];
    }
}

def load_graph(
    entities: list[str],
    edges: list[tuple[str, str]],
) -> EdgeGraph {
    g = EdgeGraph();
    for eid in entities {
        if eid not in g.entities {
            nd = Entity(eid=eid);
            root ++> nd;
            g.entities[eid] = nd;
        }
    }
    for (src, dst) in edges {
        a = g.entities.get(src, None);
        b = g.entities.get(dst, None);
        if a is not None and b is not None { a +>:LinksTo:+> b; }
    }
    return g;
}

def neighbors_at_hop(g: EdgeGraph, entity_id: str, hops: int) -> list[str] {
    if entity_id not in g.entities or hops < 1 { return []; }
    anchor = g.entities[entity_id];
    w = anchor spawn HopFrontier(
        depth=0,
        max_depth=hops,
        claimed={},
        frontier=[],
    );
    return sorted(w.frontier);
}

def all_reachable(g: EdgeGraph, entity_id: str, max_hops: int = 3) -> list[str] {
    if entity_id not in g.entities { return []; }
    anchor = g.entities[entity_id];
    w = anchor spawn ReachCollect(
        max_hops=max_hops,
        claimed={},
        reached=[],
        depth=0,
    );
    return sorted(w.reached);
}

walker CycleProbe {
    has target: str = "";
    has path: list[str] = [];
    has found: bool = False;
    can step with Entity entry {
        if here.eid in self.path {
            if here.eid == self.target and len(self.path) > 0 { self.found = True; }
            skip;
        }
        self.path = self.path + [here.eid];
        if len(self.path) > 1 and here.eid == self.target { self.found = True; disengage; }
        visit [->:LinksTo:->][?:Entity];
    }
}

def has_cycle(g: EdgeGraph) -> bool {
    for (eid, nd) in g.entities.items() {
        w = nd spawn CycleProbe(target=eid, path=[], found=False);
        if w.found { return True; }
    }
    return False;
}
