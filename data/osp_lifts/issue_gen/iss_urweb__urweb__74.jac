"""urweb/urweb#74 — recursive CTE reachability (WITH RECURSIVE analog)."""

node Row {
    has cid: str;
}

edge Next {}

obj CteState {
    has claimed: dict[str, bool] = {};
    has collected: list[str] = [];
    has max_depth: int = -1;
}

def ensure_row(store: dict[str, Row], cid: str) -> Row {
    if cid in store {
        return store[cid];
    }
    nd = Row(cid=cid);
    store[cid] = nd;
    return nd;
}

def build_cte_graph(edges: list[tuple[str, str]]) -> Row {
    store: dict[str, Row] = {};
    for pair in edges {
        src_id = pair[0];
        dst_id = pair[1];
        src_nd = ensure_row(store, src_id);
        dst_nd = ensure_row(store, dst_id);
        src_nd +>:Next:+> dst_nd;
    }
    graph_root = Row(cid="__root__");
    for cid in store {
        nd = store[cid];
        graph_root +>:Next:+> nd;
    }
    return graph_root;
}

walker IndexWalk {
    has claimed: dict[str, bool] = {};
    has by_id: dict[str, Row] = {};

    can index with Row entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.by_id[here.cid] = here;
        print("index ", here.cid);
        kids: list[Row] = [];
        for ch in [here ->:Next:->][?:Row] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        }
    }
}

walker CteRecursive {
    has state: CteState;
    has cur_depth: int = 0;

    can recurse with Row entry {
        if here.cid in self.state.claimed {
            skip;
        }
        self.state.claimed[here.cid] = True;
        self.state.collected.append(here.cid);
        print("cte ", here.cid);
        if self.state.max_depth >= 0 and self.cur_depth >= self.state.max_depth {
            skip;
        }
        kids: list[Row] = [];
        for ch in [here ->:Next:->][?:Row] {
            kids.append(ch);
        }
        if kids {
            self.cur_depth = self.cur_depth + 1;
            visit :0: kids;
            self.cur_depth = self.cur_depth - 1;
        }
    }
}

def index_rows(graph_root: Row) -> dict[str, Row] {
    wk = graph_root spawn IndexWalk();
    return wk.by_id;
}

def cte_closure(seeds: list[str], graph_root: Row, max_depth: int = -1) -> list[str] {
    by_id = index_rows(graph_root);
    state = CteState(max_depth=max_depth);
    start_nodes: list[Row] = [];
    for sid in seeds {
        if sid in by_id {
            start_nodes.append(by_id[sid]);
        }
    }
    for nd in start_nodes {
        wk = nd spawn CteRecursive(state=state, cur_depth=0);
    }
    out: list[str] = sorted(state.collected);
    return out;
}

def cte_contains(seeds: list[str], graph_root: Row, target: str) -> bool {
    rows = cte_closure(seeds, graph_root, -1);
    for cid in rows {
        if cid == target {
            return True;
        }
    }
    return False;
}
