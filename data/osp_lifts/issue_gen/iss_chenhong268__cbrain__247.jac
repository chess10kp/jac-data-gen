# chenhong268/cbrain#247 — local graph reasoning layer for CBrain
# Unified BFS/DFS traversal core with depth limits and provenance-safe
# local relevance ranking over stored edges.

node Entity {
    has eid: str;
    has label: str = "";
    has trust_state: str = "candidate";
}

edge Rel {
    has rtype: str = "related";
    has weight: float = 1.0;
    has confidence: float = 1.0;
}

graph brain_graph {
    has entities: dict[str, Entity] = {};
}

def get_entity(g: brain_graph, eid: str) -> Entity | None {
    if eid in g.entities {
        return g.entities[eid];
    }
    return None;
}

def add_entity(g: brain_graph, eid: str, label: str) -> Entity {
    nd = Entity(eid=eid, label=label);
    root ++> nd;
    g.entities[eid] = nd;
    return nd;
}

def link(g: brain_graph, src: str, dst: str, rtype: str, weight: float) -> bool {
    a = get_entity(g, src);
    b = get_entity(g, dst);
    if a is None or b is None {
        return False;
    }
    a +>:Rel(rtype=rtype, weight=weight):+> b;
    return True;
}

walker Bfs {
    has max_depth: int = 3;
    has depth: int = 0;
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Entity entry {
        if here.eid in self.claimed {
            skip;
        }
        self.claimed[here.eid] = True;
        self.order.append(here.eid);
        if self.depth >= self.max_depth {
            disengage;
        }
        kids: list[Entity] = [here ->:Rel:->];
        kids = sorted(kids, key=lambda k: k.eid);
        if len(kids) == 0 {
            disengage;
        }
        self.depth += 1;
        visit kids;
    }
}

def bfs_closure(g: brain_graph, start: str, max_depth: int) -> list[str] {
    src = get_entity(g, start);
    if src is None {
        return [];
    }
    w = src spawn Bfs(max_depth=max_depth, claimed={});
    out: list[str] = [];
    for x in w.order {
        out.append(x);
    }
    return sorted(out);
}

walker Dfs {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Entity entry {
        if here.eid in self.claimed {
            skip;
        }
        self.claimed[here.eid] = True;
        self.order.append(here.eid);
        kids: list[Entity] = [here ->:Rel:->];
        kids = sorted(kids, key=lambda k: k.eid);
        for kid in kids {
            visit :0: [kid];
        }
    }
}

def dfs_closure(g: brain_graph, start: str) -> list[str] {
    src = get_entity(g, start);
    if src is None {
        return [];
    }
    w = src spawn Dfs(claimed={});
    return sorted(w.order);
}

def local_rank(g: brain_graph, start: str, max_depth: int) -> dict[str, float] {
    src = get_entity(g, start);
    if src is None {
        return {};
    }
    scores: dict[str, float] = {};
    w = src spawn Bfs(max_depth=max_depth, claimed={});
    # deterministic one-score-per-hop: nearer nodes score higher
    for i in range(len(w.order)) {
        eid = w.order[i];
        if eid != start {
            scores[eid] = 1.0 / float(i + 1);
        }
    }
    return scores;
}
