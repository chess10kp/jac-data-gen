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

test "bfs_unknown_start" {
    g = brain_graph();
    assert bfs_closure(g, "nope", 2) == [];
}

test "bfs_depth_limit" {
    g = brain_graph();
    add_entity(g, "a", "A");
    add_entity(g, "b", "B");
    add_entity(g, "c", "C");
    add_entity(g, "d", "D");
    assert link(g, "a", "b", "rel", 1.0);
    assert link(g, "b", "c", "rel", 1.0);
    assert link(g, "c", "d", "rel", 1.0);
    assert bfs_closure(g, "a", 2) == ["a", "b", "c"];
    assert bfs_closure(g, "a", 5) == ["a", "b", "c", "d"];
    assert dfs_closure(g, "a") == ["a", "b", "c", "d"];
}

test "bfs_cycle_terminates" {
    g = brain_graph();
    add_entity(g, "a", "A");
    add_entity(g, "b", "B");
    assert link(g, "a", "b", "rel", 1.0);
    assert link(g, "b", "a", "rel", 1.0);
    assert bfs_closure(g, "a", 10) == ["a", "b"];
    assert dfs_closure(g, "a") == ["a", "b"];
}

test "link_unknown_returns_false" {
    g = brain_graph();
    add_entity(g, "a", "A");
    assert link(g, "a", "ghost", "rel", 1.0) == False;
    assert link(g, "ghost", "a", "rel", 1.0) == False;
}

test "local_rank_scores" {
    g = brain_graph();
    add_entity(g, "a", "A");
    add_entity(g, "b", "B");
    add_entity(g, "c", "C");
    assert link(g, "a", "b", "rel", 1.0);
    assert link(g, "a", "c", "rel", 1.0);
    r = local_rank(g, "a", 1);
    assert "a" not in r;
    assert r["b"] == 0.5 and r["c"] == 0.5;
    r2 = local_rank(g, "zz", 2);
    assert len(r2) == 0;
}
