"""Tree renderer cycle blow-up inspired by gastownhall/beads#5887."""

obj DepStore {
    has stamp: int = 0;
}

node DepNode {
    has node_id: str;
}

edge Depends {}

walker NaiveRender {
    has root_id: str;
    has active: dict[str, bool] = {};
    has order: list[str] = [];
    has reports: list[list[str]] = [];

    can launch with Root entry {
        visit [-->][?:DepNode, node_id == self.root_id];
    }

    can seed with DepNode entry {
        if here.node_id in self.active and self.active[here.node_id] {
            skip;
        }
        self.active[here.node_id] = True;
        self.order.append(here.node_id);
        visit [-->][?:DepNode] else {
            self.active[here.node_id] = False;
            disengage;
        };
    }

    can walk with DepNode entry {
        if here.node_id in self.active and self.active[here.node_id] {
            skip;
        }
        self.active[here.node_id] = True;
        self.order.append(here.node_id);
        visit [-->][?:DepNode] else {
            self.active[here.node_id] = False;
            disengage;
        };
    }

    can unwind with DepNode exit {
        self.active[here.node_id] = False;
    }

    can finish with Root exit {
        report self.order;
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

walker SafeRender {
    has root_id: str;
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has reports: list[list[str]] = [];

    can launch with Root entry {
        visit [-->][?:DepNode, node_id == self.root_id];
    }

    can seed with DepNode entry {
        if here.node_id in self.claimed {
            skip;
        }
        self.claimed[here.node_id] = True;
        self.order.append(here.node_id);
        visit [-->][?:DepNode] else {
            disengage;
        };
    }

    can walk with DepNode entry {
        if here.node_id in self.claimed {
            skip;
        }
        self.claimed[here.node_id] = True;
        self.order.append(here.node_id);
        visit [-->][?:DepNode] else {
            disengage;
        };
    }

    can finish with Root exit {
        report self.order;
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

def render_tree_naive(store: DepStore, root_id: str) -> list[str] {
    _ = store;
    hit = [root -->][?:DepNode, node_id == root_id];
    if not hit {
        raise KeyError(root_id);
    }
    result = root spawn NaiveRender(root_id=root_id);
    return result.reports[0] if result.reports else [];
}

def has_cycle(store: DepStore) -> bool {
    _ = store;
    result = root spawn CycleDetector();
    return result.reports[0] if result.reports else False;
}

def render_tree(store: DepStore, root_id: str) -> list[str] {
    _ = store;
    if has_cycle(store) {
        raise ValueError("cycle detected");
    }
    hit = [root -->][?:DepNode, node_id == root_id];
    if not hit {
        raise KeyError(root_id);
    }
    result = root spawn SafeRender(root_id=root_id);
    return result.reports[0] if result.reports else [];
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
