"""zio/zio-quill#966 — recursive responsibility descendant query."""

node Responsibility {
    has resp_id: int;
    has long_name: str;
    has short_name: str = "";
}

edge ChildOf {}

node RespGraph {
    has seeds: dict[str, list[int]] = {};
    has by_id: dict[int, Responsibility] = {};
}

walker RecursivePairs {
    has user_id: int;
    has role_id: int;
    has claimed: dict[int, bool] = {};
    has found: list[tuple[str, str]] = [];

    can begin_graph with RespGraph entry {
        print({"walk": "recursive_pairs", "user": self.user_id, "role": self.role_id});
        key: str = str(self.user_id) + ":" + str(self.role_id);
        seeds: list[Responsibility] = [];
        if key in here.seeds {
            for sid in here.seeds[key] {
                if sid in here.by_id {
                    seeds.append(here.by_id[sid] as Responsibility);
                }
            }
        }
        if seeds {
            visit :0: seeds;
        } else {
            disengage;
        }
    }

    can descend_resp with Responsibility entry {
        if here.resp_id in self.claimed {
            skip;
        }
        self.claimed[here.resp_id] = True;
        row: tuple[str, str] = (here.long_name, here.short_name);
        self.found.append(row);
        kids: list[Responsibility] = [];
        for ch in [here ->:ChildOf:->][?:Responsibility] {
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        }
    }
}

def make_graph -> RespGraph {
    g = RespGraph();
    root ++> g;
    return g;
}

def add_responsibility(graph_root: RespGraph, resp_id: int, long_name: str, short_name: str) -> Responsibility {
    nd = Responsibility(resp_id=resp_id, long_name=long_name, short_name=short_name);
    graph_root.by_id[resp_id] = nd;
    graph_root ++> nd;
    return nd;
}

def link_child(parent_id: int, child_id: int, graph_root: RespGraph) -> None {
    if parent_id not in graph_root.by_id {
        return None;
    }
    if child_id not in graph_root.by_id {
        return None;
    }
    parent_nd = graph_root.by_id[parent_id] as Responsibility;
    child_nd = graph_root.by_id[child_id] as Responsibility;
    parent_nd +>:ChildOf:+> child_nd;
    return None;
}

def bind_user_role(user_id: int, role_id: int, resp_id: int, graph_root: RespGraph) -> None {
    key: str = str(user_id) + ":" + str(role_id);
    bucket: list[int] = [];
    if key in graph_root.seeds {
        bucket = graph_root.seeds[key];
    }
    bucket.append(resp_id);
    graph_root.seeds[key] = bucket;
    return None;
}

def recursive_pairs(user_id: int, role_id: int, graph_root: RespGraph) -> list[tuple[str, str]] {
    w = graph_root spawn RecursivePairs(user_id=user_id, role_id=role_id);
    out: list[tuple[str, str]] = w.found;
    out.sort();
    return out;
}

test "empty_when_unbound" {
    g = make_graph();
    add_responsibility(g, 1, "Root", "R");
    assert recursive_pairs(9, 9, g) == [];
}

test "single_seed_descendants" {
    g = make_graph();
    add_responsibility(g, 1, "Alpha", "A");
    add_responsibility(g, 2, "Beta", "B");
    link_child(1, 2, g);
    bind_user_role(1, 1, 1, g);
    assert recursive_pairs(1, 1, g) == [("Alpha", "A"), ("Beta", "B")];
}

test "multiple_seeds" {
    g = make_graph();
    add_responsibility(g, 1, "One", "1");
    add_responsibility(g, 2, "Two", "2");
    bind_user_role(3, 4, 1, g);
    bind_user_role(3, 4, 2, g);
    assert recursive_pairs(3, 4, g) == [("One", "1"), ("Two", "2")];
}

test "cycle_skip_once" {
    g = make_graph();
    add_responsibility(g, 1, "A", "a");
    add_responsibility(g, 2, "B", "b");
    link_child(1, 2, g);
    link_child(2, 1, g);
    bind_user_role(5, 5, 1, g);
    assert recursive_pairs(5, 5, g) == [("A", "a"), ("B", "b")];
}

test "diamond_sorted" {
    g = make_graph();
    add_responsibility(g, 1, "Top", "T");
    add_responsibility(g, 2, "Left", "L");
    add_responsibility(g, 3, "Right", "R");
    add_responsibility(g, 4, "Join", "J");
    link_child(1, 2, g);
    link_child(1, 3, g);
    link_child(2, 4, g);
    link_child(3, 4, g);
    bind_user_role(7, 7, 1, g);
    assert recursive_pairs(7, 7, g) == [("Join", "J"), ("Left", "L"), ("Right", "R"), ("Top", "T")];
}

test "unknown_link_ids_ignored" {
    g = make_graph();
    add_responsibility(g, 1, "Only", "O");
    link_child(1, 99, g);
    link_child(99, 1, g);
    bind_user_role(2, 2, 1, g);
    assert recursive_pairs(2, 2, g) == [("Only", "O")];
}
