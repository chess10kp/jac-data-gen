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
