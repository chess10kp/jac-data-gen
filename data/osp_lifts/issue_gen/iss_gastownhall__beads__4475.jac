"""gastownhall/beads#4475 — Dependency cycle detection (CTE-safe vs naive path DFS)."""

obj DepStore {
    has stamp: int = 0;
}

node DepNode {
    has node_id: str;
}

edge Depends {}

walker NaiveCycleProbe {
    has start_id: str;
    has active: dict[str, bool] = {};
    has found: bool = False;
    has reports: list[bool] = [];

    can launch with Root entry {
        visit [-->][?:DepNode];
    }

    can seed with DepNode entry {
        if here.node_id != self.start_id {
            visit [-->];
            return;
        }
        if here.node_id in self.active and self.active[here.node_id] {
            self.found = True;
            skip;
        }
        self.active[here.node_id] = True;
        visit [-->][?:DepNode] else {
            self.active[here.node_id] = False;
            disengage;
        };
    }

    can walk with DepNode entry {
        if self.found {
            skip;
        }
        if here.node_id in self.active and self.active[here.node_id] {
            self.found = True;
            skip;
        }
        self.active[here.node_id] = True;
        visit [-->][?:DepNode] else {
            self.active[here.node_id] = False;
            disengage;
        };
    }

    can unwind with DepNode exit {
        self.active[here.node_id] = False;
    }

    can finish with Root exit {
        report self.found;
    }
}

walker CycleDetector {
    has claimed: dict[str, bool] = {};
    has active: dict[str, bool] = {};
    has found: bool = False;
    has reports: list[bool] = [];

    can begin with Root entry {
        visit [-->][?:DepNode];
    }

    can probe with DepNode entry {
        if self.found {
            skip;
        }
        if here.node_id in self.active and self.active[here.node_id] {
            self.found = True;
            skip;
        }
        if here.node_id in self.claimed {
            skip;
        }
        self.claimed[here.node_id] = True;
        self.active[here.node_id] = True;
        visit [-->][?:DepNode] else {
            self.active[here.node_id] = False;
            disengage;
        };
    }

    can unwind with DepNode exit {
        self.active[here.node_id] = False;
    }

    can finish with Root exit {
        report self.found;
    }
}

def build_dependency_graph(edges: list[tuple[str, str]]) -> DepStore {
    id_map: dict[str, DepNode] = {};
    for (src, dst) in edges {
        if src not in id_map {
            n = DepNode(node_id=src);
            root ++> n;
            id_map[src] = n;
        }
        if dst not in id_map {
            n = DepNode(node_id=dst);
            root ++> n;
            id_map[dst] = n;
        }
    }
    for (src, dst) in edges {
        id_map[src] +>:Depends:+> id_map[dst];
    }
    return DepStore(stamp=1);
}

def has_cycle_naive(store: DepStore) -> bool {
    _ = store;
    for n in [-->][?:DepNode] {
        result = root spawn NaiveCycleProbe(start_id=n.node_id);
        if result.reports and result.reports[0] {
            return True;
        }
    }
    return False;
}

def has_cycle(store: DepStore) -> bool {
    _ = store;
    result = root spawn CycleDetector();
    if result.reports {
        return result.reports[0];
    }
    return False;
}

def all_nodes(store: DepStore) -> list[str] {
    _ = store;
    ids: list[str] = [];
    for n in [-->][?:DepNode] {
        ids.append(n.node_id);
    }
    ids.sort();
    return ids;
}
