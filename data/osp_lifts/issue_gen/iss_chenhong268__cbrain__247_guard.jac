"""chenhong268/cbrain#247 - graph traversal as local reasoning layer."""

node Entity {
    has cid: str;
    has label: str = "";
}

edge Relates {
    has rel_type: str = "relates";
}

def sort_entities_by_cid(nodes: list[Entity]) -> list[Entity] {
    ids: list[str] = [];
    for nd in nodes {
        ids.append(nd.cid);
    }
    ids = sorted(ids);
    out: list[Entity] = [];
    for sid in ids {
        for nd in nodes {
            if nd.cid == sid {
                out.append(nd);
            }
        }
    }
    return out;
}

def reverse_ids(xs: list[str]) -> list[str] {
    out: list[str] = [];
    i = len(xs) - 1;
    while i >= 0 {
        out.append(xs[i]);
        i -= 1;
    }
    return out;
}

def lookup_entity(graph_root: Entity, node_id: str) -> Entity | None {
    if graph_root.cid == node_id {
        return graph_root;
    }
    claimed: dict[str, bool] = {};
    stack: list[Entity] = [graph_root];
    while stack {
        cur = stack.pop();
        if cur.cid in claimed {
            continue;
        }
        claimed[cur.cid] = True;
        if cur.cid == node_id {
            return cur;
        }
        chs: list[Entity] = [cur ->:Relates:->][?:Entity];
        for ch in chs {
            stack.append(ch);
        }
    }
    return None;
}

def add_link(
    graph_root: Entity,
    src_id: str,
    dst_id: str,
    rel_type: str = "relates",
) -> bool {
    src = lookup_entity(graph_root, src_id);
    dst = lookup_entity(graph_root, dst_id);
    if src is None or dst is None {
        return False;
    }
    src +>:Relates(rel_type=rel_type):+> dst;
    return True;
}

walker ExplainTrace {
    has claimed: dict[str, bool] = {};
    has max_depth: int = 10;
    has depth: int = 0;
    has order: list[str] = [];

    can step with Entity entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print ["trace", here.cid, self.depth];
        if self.depth >= self.max_depth {
            disengage;
        }
        kids: list[Entity] = [here ->:Relates:->][?:Entity];
        sorted_kids: list[Entity] = sort_entities_by_cid(kids);
        nxt = self.depth + 1;
        for kid in sorted_kids {
            kid spawn ExplainTrace(
                claimed=self.claimed,
                max_depth=self.max_depth,
                depth=nxt,
                order=self.order,
            );
        }
        disengage;
    }
}

walker BfsReach {
    has claimed: dict[str, bool] = {};
    has max_depth: int = 2;
    has depth: int = 0;
    has start_id: str = "";
    has found: list[str] = [];

    can hop with Entity entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print ["bfs_visit", here.cid, self.depth];
        if here.cid != self.start_id {
            self.found.append(here.cid);
        }
        if self.depth >= self.max_depth {
            disengage;
        }
        kids: list[Entity] = [here ->:Relates:->][?:Entity];
        nxt = self.depth + 1;
        for kid in kids {
            kid spawn BfsReach(
                claimed=self.claimed,
                max_depth=self.max_depth,
                depth=nxt,
                start_id=self.start_id,
                found=self.found,
            );
        }
        disengage;
    }
}

walker ShortestPath {
    has claimed: dict[str, bool] = {};
    has max_depth: int = 10;
    has depth: int = 0;
    has end_id: str = "";
    has parent: dict[str, str] = {};
    has hit: bool = False;

    can hop with Entity entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print ["path_visit", here.cid, self.depth];
        if here.cid == self.end_id {
            self.hit = True;
            disengage;
        }
        if self.depth >= self.max_depth {
            disengage;
        }
        kids: list[Entity] = [here ->:Relates:->][?:Entity];
        for kid in kids {
            if kid.cid not in self.parent {
                self.parent[kid.cid] = here.cid;
            }
        }
        visit kids;
    }
}

walker CascadeRank {
    has claimed: dict[str, bool] = {};
    has max_depth: int = 3;
    has depth: int = 0;
    has start_id: str = "";
    has ranks: dict[str, int] = {};

    can rank with Entity entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print ["cascade", here.cid, self.depth];
        if here.cid != self.start_id {
            old = self.ranks.get(here.cid, 9999);
            if self.depth < old {
                self.ranks[here.cid] = self.depth;
            }
        }
        if self.depth >= self.max_depth {
            disengage;
        }
        nxt = self.depth + 1;
        kids: list[Entity] = [here ->:Relates:->][?:Entity];
        for kid in kids {
            kid spawn CascadeRank(
                claimed=self.claimed,
                max_depth=self.max_depth,
                depth=nxt,
                start_id=self.start_id,
                ranks=self.ranks,
            );
        }
        disengage;
    }
}

def new_graph() -> Entity {
    graph_root = Entity(cid="__graph__", label="local");
    root ++> graph_root;
    return graph_root;
}

def ensure_entity(graph_root: Entity, node_id: str, label: str = "") -> Entity {
    hit = lookup_entity(graph_root, node_id);
    if hit is not None {
        return hit;
    }
    nd = Entity(cid=node_id, label=label);
    graph_root ++> nd;
    return nd;
}

def seed_graph(
    graph_root: Entity,
    edges: list[tuple[str, str, str]] | None = None,
) -> None {
    rows: list[tuple[str, str, str]] = edges if edges is not None else [];
    for row in rows {
        src_id = row[0];
        dst_id = row[1];
        rel_type = row[2];
        ensure_entity(graph_root, src_id);
        ensure_entity(graph_root, dst_id);
        add_link(graph_root, src_id, dst_id, rel_type);
    }
}

def explain_trace_order(
    graph_root: Entity,
    start_id: str,
    max_depth: int = 10,
) -> list[str] {
    start = lookup_entity(graph_root, start_id);
    if start is None {
        return [];
    }
    w = start spawn ExplainTrace(
        claimed={},
        max_depth=max_depth,
        depth=0,
        order=[],
    );
    print ["trace_done", start_id, len(w.order)];
    return w.order;
}

def bfs_reachable(
    graph_root: Entity,
    start_id: str,
    max_depth: int = 2,
) -> list[str] {
    start = lookup_entity(graph_root, start_id);
    if start is None {
        return [];
    }
    w = start spawn BfsReach(
        claimed={},
        max_depth=max_depth,
        depth=0,
        start_id=start_id,
        found=[],
    );
    print ["bfs_done", start_id, len(w.found)];
    return sorted(w.found);
}

def shortest_explain_path(
    graph_root: Entity,
    start_id: str,
    end_id: str,
    max_depth: int = 10,
) -> list[str] | None {
    start = lookup_entity(graph_root, start_id);
    end = lookup_entity(graph_root, end_id);
    if start is None or end is None {
        return None;
    }
    if start_id == end_id {
        return [start_id];
    }
    w = start spawn ShortestPath(
        claimed={},
        max_depth=max_depth,
        depth=0,
        end_id=end_id,
        parent={start_id: start_id},
        hit=False,
    );
    if not w.hit {
        return None;
    }
    path_rev: list[str] = [];
    cur_id = end_id;
    while cur_id != start_id {
        path_rev.append(cur_id);
        if cur_id not in w.parent {
            return None;
        }
        cur_id = w.parent[cur_id];
    }
    path_rev.append(start_id);
    return reverse_ids(path_rev);
}

def cascade_rank(
    graph_root: Entity,
    start_id: str,
    max_depth: int = 3,
) -> dict[str, int] {
    start = lookup_entity(graph_root, start_id);
    if start is None {
        return {};
    }
    w = start spawn CascadeRank(
        claimed={},
        max_depth=max_depth,
        depth=0,
        start_id=start_id,
        ranks={},
    );
    print ["cascade_done", start_id, len(w.ranks)];
    return w.ranks;
}

test "explain_trace_order_join_tree" {
    g = new_graph();
    seed_graph(
        g,
        [
            ("join", "left", "relates"),
            ("join", "right", "relates"),
            ("join", "leaf", "relates"),
        ],
    );
    ot = explain_trace_order(g, "join", 5);
    assert ot == ["join", "leaf", "left", "right"];
}

test "shortest_path_known_route" {
    g = new_graph();
    seed_graph(
        g,
        [
            ("s", "m", "relates"),
            ("m", "t", "relates"),
        ],
    );
    assert shortest_explain_path(g, "s", "t", 5) == ["s", "m", "t"];
}

test "shortest_path_unknown_end_returns_none" {
    g = new_graph();
    seed_graph(g, [("s", "m", "relates")]);
    assert shortest_explain_path(g, "s", "missing", 5) is None;
}

test "cascade_rank_cycle_skips_without_truncating_closure" {
    g = new_graph();
    seed_graph(
        g,
        [
            ("a", "b", "relates"),
            ("b", "a", "relates"),
            ("a", "c", "relates"),
        ],
    );
    ranks = cascade_rank(g, "a", 3);
    assert ranks["b"] == 1;
    assert ranks["c"] == 1;
}

test "bfs_zero_depth_excludes_neighbors" {
    g = new_graph();
    seed_graph(g, [("x", "y", "relates")]);
    assert bfs_reachable(g, "x", 0) == [];
}

test "bfs_depth_one_includes_direct_neighbor" {
    g = new_graph();
    seed_graph(
        g,
        [
            ("x", "y", "relates"),
            ("y", "z", "relates"),
        ],
    );
    assert bfs_reachable(g, "x", 1) == ["y"];
}
