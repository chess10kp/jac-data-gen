"""git-stunts/git-warp#220 — BFS/DFS ordering and directed cycle detection."""

node G {
    has cid: str;
}

edge Arc {}

def find_node(graph_root: G, target: str) -> G | None {
    if graph_root.cid == target {
        return graph_root;
    }
    for ch in [graph_root ->:Arc:->][?:G] {
        hit = find_node(ch, target);
        if hit != None {
            return hit;
        }
    }
    return None;
}

def sort_neighbors(kids: list[G]) -> list[G] {
    sorted_kids: list[G] = [];
    cids: list[str] = [];
    for k in kids {
        cids.append(k.cid);
    }
    cids = sorted(cids);
    for cid in cids {
        for k in kids {
            if k.cid == cid {
                sorted_kids.append(k);
            }
        }
    }
    return sorted_kids;
}

walker BfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with G entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        kids: list[G] = [here ->:Arc:->][?:G];
        sorted_kids = sort_neighbors(kids);
        if len(sorted_kids) > 0 {
            visit sorted_kids;
        }
        print(self.order);
    }
}

walker DfsWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with G entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        kids: list[G] = [here ->:Arc:->][?:G];
        sorted_kids = sort_neighbors(kids);
        idx = len(sorted_kids) - 1;
        while idx >= 0 {
            visit :0: [sorted_kids[idx]];
            idx = idx - 1;
        }
        print(self.order);
    }
}

walker CycleWalker {
    has on_stack: dict[str, bool] = {};
    has done: dict[str, bool] = {};
    has found: bool = False;

    can probe with G entry {
        if here.cid in self.done {
            skip;
        }
        if here.cid in self.on_stack {
            self.found = True;
            skip;
        }
        self.on_stack[here.cid] = True;
        kids: list[G] = [here ->:Arc:->][?:G];
        sorted_kids = sort_neighbors(kids);
        for ch in sorted_kids {
            if ch.cid in self.on_stack {
                self.found = True;
            } else {
                if not (ch.cid in self.done) {
                    visit [ch];
                }
            }
        }
        self.on_stack[here.cid] = False;
        self.done[here.cid] = True;
        print(self.found);
    }
}

def bfs_order(graph_root: G, start_cid: str) -> list[str] {
    start_nd = find_node(graph_root, start_cid);
    if start_nd == None {
        return [];
    }
    w = start_nd spawn BfsWalker(claimed={}, order=[]);
    print(w.order);
    return w.order;
}

def dfs_order(graph_root: G, start_cid: str) -> list[str] {
    start_nd = find_node(graph_root, start_cid);
    if start_nd == None {
        return [];
    }
    w = start_nd spawn DfsWalker(claimed={}, order=[]);
    print(w.order);
    return w.order;
}

def has_directed_cycle(graph_root: G) -> bool {
    w = graph_root spawn CycleWalker(on_stack={}, done={}, found=False);
    print(w.found);
    return w.found;
}
