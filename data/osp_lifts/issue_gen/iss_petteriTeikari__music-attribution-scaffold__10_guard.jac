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

def has_cycle(g: EdgeGraph) -> bool {
    for start in sorted(g.entities.keys()) {
        state: dict[str, int] = {};
        stack: list[str] = [start];
        while len(stack) > 0 {
            cur = stack[len(stack) - 1];
            nd = g.entities.get(cur, None);
            if nd is None {
                stack = stack[0 : len(stack) - 1];
                continue;
            }
            st = state.get(cur, 0);
            if st == 0 {
                state[cur] = 1;
                pushed = False;
                for nb in [nd ->:LinksTo:->][?:Entity] {
                    if state.get(nb.eid, 0) == 1 { return True; }
                    if state.get(nb.eid, 0) == 0 {
                        stack.append(nb.eid);
                        pushed = True;
                    }
                }
                if not pushed {
                    state[cur] = 2;
                    stack = stack[0 : len(stack) - 1];
                }
            } elif st == 1 {
                state[cur] = 2;
                stack = stack[0 : len(stack) - 1];
            } else {
                stack = stack[0 : len(stack) - 1];
            }
        }
    }
    return False;
}
test "multi-hop neighbors" {
    g = load_graph(["a", "b", "c", "d"], [("a", "b"), ("b", "c"), ("c", "d")]);
    assert neighbors_at_hop(g, "a", 1) == ["b"];
    assert neighbors_at_hop(g, "a", 2) == ["c"];
    assert all_reachable(g, "a", 3) == ["b", "c", "d"];
}
test "diamond adversarial revisit" {
    g = load_graph(["root", "left", "right", "leaf"],
        [("root", "left"), ("root", "right"), ("left", "leaf"), ("right", "leaf")]);
    assert all_reachable(g, "root", 3) == ["leaf", "left", "right"];
}
test "cycle detect" {
    g = load_graph(["x", "y", "z"], [("x", "y"), ("y", "z"), ("z", "x")]);
    assert has_cycle(g) is True;
}
test "unknown entity tolerant" {
    g = load_graph(["solo"], []);
    assert neighbors_at_hop(g, "missing", 1) == [];
}
