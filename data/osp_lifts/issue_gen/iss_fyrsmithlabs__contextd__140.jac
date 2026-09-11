"""fyrsmithlabs/contextd#140 — Entity graph multi-hop relationship reach."""

obj EntityGraph {
    has entities: dict[str, Entity] = {};
}

node Entity { has eid: str; }
edge Relates {}

walker EntityReach {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has max_depth: int = 0;
    has depth: dict[str, int] = {};

    can step with Entity entry {
        if here.eid in self.claimed { skip; }
        cur_d = self.depth.get(here.eid, 0);
        if cur_d > self.max_depth { disengage; }
        self.claimed[here.eid] = True;
        self.reached.append(here.eid);
        for nxt in [here ->:Relates:->][?:Entity] {
            nd = cur_d + 1;
            if nd <= self.max_depth {
                self.depth[nxt.eid] = nd;
                visit [nxt];
            }
        }
    }
}

def load_entity_graph(
    entities: list[str],
    relates_edges: list[tuple[str, str]],
) -> EntityGraph {
    g = EntityGraph();
    for eid in entities {
        if eid not in g.entities {
            nd = Entity(eid=eid);
            root ++> nd;
            g.entities[eid] = nd;
        }
    }
    for (src, dst) in relates_edges {
        s = g.entities.get(src, None);
        d = g.entities.get(dst, None);
        if s is not None and d is not None { s +>:Relates:+> d; }
    }
    return g;
}

def reachable_entities(g: EntityGraph, start: str, max_depth: int) -> list[str] {
    anchor = g.entities.get(start, None);
    if anchor is None or max_depth < 0 { return []; }
    w = anchor spawn EntityReach(
        claimed={},
        reached=[],
        max_depth=max_depth,
        depth={start: 0},
    );
    return sorted(w.reached);
}

def entity_neighbors(g: EntityGraph, entity_id: str) -> list[str] {
    anchor = g.entities.get(entity_id, None);
    if anchor is None { return []; }
    out: list[str] = [];
    for nxt in [anchor ->:Relates:->][?:Entity] { out.append(nxt.eid); }
    return sorted(out);
}
