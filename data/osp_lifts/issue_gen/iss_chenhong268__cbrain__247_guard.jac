# chenhong268/cbrain#247 — local graph reasoning layer (BFS/DFS traversal core)

node Entity {
    has eid: str;
    has label: str = "";
}

edge REL {
    has rel_type: str = "related";
    has weight: float = 1.0;
    has trust_state: str = "candidate";
}

def build(graph_root: Entity, nodes: list[Entity]) -> None {
    for nd in nodes { root ++> nd; }
}

def fetch(eid: str, table: dict[str, Entity]) -> Entity | None {
    if eid in table { return table[eid]; }
    return None;
}

walker BFS {
    has max_depth: int = 3;
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has depths: dict[str, int] = {};

    can step with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        self.order.append(here.eid);
        my_d: int = 0;
        if here.eid in self.depths { my_d = self.depths[here.eid]; }
        if my_d < self.max_depth {
            kids: list[Entity] = [here ->:REL:->][?:Entity];
            for k in kids {
                if k.eid not in self.depths { self.depths[k.eid] = my_d + 1; }
            }
            visit kids;
        }
        print("bfs claimed:", sorted(self.claimed.keys()));
    }
}

walker DFS {
    has start_eid: str;
    has claimed: dict[str, bool] = {};
    has found: str = "";

    can hunt with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        if here.eid == self.start_eid { self.found = here.eid; }
        if self.found == "" {
            kids: list[Entity] = [];
            for k in [here ->:REL:->][?:Entity] { kids.append(k); }
            visit :0: kids;
        }
        print("dfs claimed:", sorted(self.claimed.keys()), "found:", self.found);
    }
}

walker DepthStats {
    has claimed: dict[str, bool] = {};
    has depth: dict[str, int] = {};
    has bridge: list[str] = [];

    can measure with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        nbrs: list[Entity] = [here ->:REL:->][?:Entity];
        self.depth[here.eid] = len(nbrs);
        if len(nbrs) >= 2 { self.bridge.append(here.eid); }
        visit nbrs;
        print("stats claimed:", sorted(self.claimed.keys()));
    }
}

test "bfs_diamond_revisit_no_truncation" {
    root ++> root spawn Entity(eid="hub");
    a = Entity(eid="a"); b = Entity(eid="b"); c = Entity(eid="c"); d = Entity(eid="d");
    a +>:REL:+> b; a +>:REL:+> c; b +>:REL:+> d; c +>:REL:+> d;
    root ++> a;
    wk = a spawn BFS(max_depth=10);
    assert len(wk.claimed) == 4;
    assert sorted(wk.order) == ["a", "b", "c", "d"];
}

test "bfs_depth_limit_stops_at_max" {
    x1 = Entity(eid="x1"); x2 = Entity(eid="x2"); x3 = Entity(eid="x3"); x4 = Entity(eid="x4");
    x1 +>:REL:+> x2; x2 +>:REL:+> x3; x3 +>:REL:+> x4;
    root ++> x1;
    wk = x1 spawn BFS(max_depth=2);
    assert sorted(wk.claimed.keys()) == ["x1", "x2", "x3"];
    assert wk.depths["x3"] == 2;
}

test "bfs_cycle_covers_all" {
    m1 = Entity(eid="m1"); m2 = Entity(eid="m2"); m3 = Entity(eid="m3");
    m1 +>:REL:+> m2; m2 +>:REL:+> m3; m3 +>:REL:+> m1;
    root ++> m1;
    wk = m1 spawn BFS(max_depth=10);
    assert len(wk.claimed) == 3;
    assert wk.order[0] == "m1";
    assert sorted(wk.order) == ["m1", "m2", "m3"];
}

test "dfs_finds_target_among_cycle" {
    y1 = Entity(eid="y1"); y2 = Entity(eid="y2"); y3 = Entity(eid="y3");
    y1 +>:REL:+> y2; y2 +>:REL:+> y3; y3 +>:REL:+> y1;
    root ++> y1;
    wk = y1 spawn DFS(start_eid="y3");
    assert wk.found == "y3";
    assert len(wk.claimed) == 3;
}

test "depth_stats_bridge_detection" {
    p = Entity(eid="p"); q = Entity(eid="q"); r = Entity(eid="r"); s = Entity(eid="s");
    p +>:REL:+> q; p +>:REL:+> r; q +>:REL:+> s; r +>:REL:+> s;
    root ++> p;
    wk = p spawn DepthStats();
    assert len(wk.claimed) == 4;
    assert wk.depth["p"] == 2 and wk.depth["s"] == 0;
    assert wk.bridge == ["p"];
}
