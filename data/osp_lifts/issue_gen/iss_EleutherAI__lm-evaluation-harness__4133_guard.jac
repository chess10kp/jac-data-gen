"""EleutherAI/lm-evaluation-harness#4133 — reject cyclic group metadata before ordering."""

node HierarchyRoot {
    has tag: str = "anchor";
}

node Group {
    has gid: str;
}

edge Subtask {}

def _collect_child_ids(group_subtasks: dict[str, list[str]]) -> dict[str, bool] {
    child_ids: dict[str, bool] = {};
    for parent_id in group_subtasks {
        subs: list[str] = group_subtasks[parent_id];
        for cid in subs {
            child_ids[cid] = True;
        }
    }
    return child_ids;
}

def _ensure_group(
    gid: str,
    nodes: dict[str, Group],
    anchor: HierarchyRoot,
) -> Group {
    if gid in nodes {
        return nodes[gid];
    }
    nd: Group = Group(gid=gid);
    nodes[gid] = nd;
    anchor ++> nd;
    return nd;
}

def _assemble_graph(
    group_subtasks: dict[str, list[str]],
    all_groups: set[str],
) -> tuple[HierarchyRoot, dict[str, Group], list[Group]] {
    anchor: HierarchyRoot = HierarchyRoot();
    root ++> anchor;
    nodes: dict[str, Group] = {};
    for gid in all_groups {
        _ensure_group(gid, nodes, anchor);
    }
    for parent_id in group_subtasks {
        parent_node: Group = _ensure_group(parent_id, nodes, anchor);
        subs: list[str] = group_subtasks[parent_id];
        for child_id in subs {
            child_node: Group = _ensure_group(child_id, nodes, anchor);
            parent_node +>:Subtask:+> child_node;
        }
    }
    child_ids: dict[str, bool] = _collect_child_ids(group_subtasks);
    roots: list[Group] = [];
    seen_root: dict[str, bool] = {};
    for gid in all_groups {
        if gid not in child_ids {
            if gid in nodes {
                if gid not in seen_root {
                    roots.append(nodes[gid]);
                    seen_root[gid] = True;
                }
            }
        }
    }
    if not roots {
        for gid in nodes {
            if gid not in child_ids {
                if gid not in seen_root {
                    roots.append(nodes[gid]);
                    seen_root[gid] = True;
                }
            }
        }
    }
    if not roots {
        for gid in nodes {
            if gid not in seen_root {
                roots.append(nodes[gid]);
                seen_root[gid] = True;
            }
        }
    }
    for r in roots {
        anchor ++> r;
    }
    return (anchor, nodes, roots);
}

walker CycleProbe {
    has claimed: dict[str, bool] = {};
    has path: list[str] = [];
    has found_cycle: bool = False;

    can scan with Group entry {
        if here.gid in self.claimed { skip; }
        on_path: bool = False;
        for seg in self.path {
            if seg == here.gid { on_path = True; }
        }
        if on_path {
            self.found_cycle = True;
            print(["cycle_hit", here.gid]);
            skip;
        }
        next_path: list[str] = [];
        for seg in self.path {
            next_path.append(seg);
        }
        next_path.append(here.gid);
        self.claimed[here.gid] = True;
        kids: list[Group] = [];
        for ch in [here ->:Subtask:->][?:Group] {
            kids.append(ch);
        }
        for kid in kids {
            sub = kid spawn CycleProbe(
                path=next_path,
                claimed=self.claimed,
                found_cycle=self.found_cycle,
            );
            if sub.found_cycle {
                self.found_cycle = True;
            }
        }
        print(["cycle_scan", here.gid, self.found_cycle]);
        disengage;
    }
}

def _graph_has_cycle(nodes: dict[str, Group]) -> bool {
    for gid in nodes {
        start: Group = nodes[gid];
        w = start spawn CycleProbe(path=[], claimed={});
        print(["cycle_probe", gid, w.found_cycle]);
        if w.found_cycle {
            return True;
        }
    }
    return False;
}

walker BuildOrder {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has depths: dict[str, int] = {};
    has cur_depth: int = 0;

    can start with HierarchyRoot entry {
        print(["order_start", here.tag]);
        entry_roots: list[Group] = [];
        for nd in [here -->][?:Group] {
            entry_roots.append(nd);
        }
        visit :0: entry_roots;
        disengage;
    }

    can descend with Group entry {
        if here.gid in self.claimed { skip; }
        self.claimed[here.gid] = True;
        self.depths[here.gid] = self.cur_depth;
        self.order.append(here.gid);
        kids: list[Group] = [];
        for ch in [here ->:Subtask:->][?:Group] {
            kids.append(ch);
        }
        saved: int = self.cur_depth;
        self.cur_depth = self.cur_depth + 1;
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
        self.cur_depth = saved;
        print(["order_visit", here.gid, self.depths[here.gid]]);
    }
}

def _build_hierarchy_info(
    group_subtasks: dict[str, list[str]],
    all_groups: set[str],
) -> tuple[list[str], dict[str, int]] {
    built = _assemble_graph(group_subtasks, all_groups);
    anchor: HierarchyRoot = built[0];
    nodes: dict[str, Group] = built[1];
    if _graph_has_cycle(nodes) {
        raise ValueError("cyclic group metadata detected");
    }
    w = anchor spawn BuildOrder(claimed={}, order=[], depths={}, cur_depth=0);
    print(["build_hierarchy_info", w.order, w.depths]);
    return (w.order, w.depths);
}

test "acyclic_linear_depths" {
    gs: dict[str, list[str]] = {"root": ["a"], "a": ["b"]};
    ag: set[str] = {"root", "a", "b"};
    res = _build_hierarchy_info(gs, ag);
    order: list[str] = res[0];
    depths: dict[str, int] = res[1];
    assert len(order) == 3;
    assert depths["root"] == 0;
    assert depths["a"] == 1;
    assert depths["b"] == 2;
    assert order[0] == "root";
}

test "unknown_subtask_id_tolerance" {
    gs: dict[str, list[str]] = {"parent": ["ghost"]};
    ag: set[str] = {"parent"};
    res = _build_hierarchy_info(gs, ag);
    order: list[str] = res[0];
    depths: dict[str, int] = res[1];
    assert "parent" in order;
    assert "ghost" in order;
    assert depths["parent"] == 0;
    assert depths["ghost"] == 1;
}

test "cyclic_pair_detected" {
    gs: dict[str, list[str]] = {"a": ["b"], "b": ["a"]};
    ag: set[str] = {"a", "b"};
    built = _assemble_graph(gs, ag);
    nodes: dict[str, Group] = built[1];
    assert _graph_has_cycle(nodes);
}

test "cyclic_raises_value_error" {
    gs: dict[str, list[str]] = {"x": ["y"], "y": ["z"], "z": ["x"]};
    ag: set[str] = {"x", "y", "z"};
    raised: bool = False;
    try {
        _build_hierarchy_info(gs, ag);
    } except ValueError {
        raised = True;
    }
    assert raised;
}

test "forest_multiset_order" {
    gs: dict[str, list[str]] = {"r1": ["c"], "r2": ["d"]};
    ag: set[str] = {"r1", "r2", "c", "d"};
    res = _build_hierarchy_info(gs, ag);
    order: list[str] = res[0];
    depths: dict[str, int] = res[1];
    assert sorted(order) == ["c", "d", "r1", "r2"];
    assert depths["r1"] == 0;
    assert depths["r2"] == 0;
    assert depths["c"] == 1;
    assert depths["d"] == 1;
}

test "diamond_acyclic_no_cycle" {
    gs: dict[str, list[str]] = {"top": ["left", "right"], "left": ["bot"], "right": ["bot"]};
    ag: set[str] = {"top", "left", "right", "bot"};
    built = _assemble_graph(gs, ag);
    nodes: dict[str, Group] = built[1];
    assert not _graph_has_cycle(nodes);
    res = _build_hierarchy_info(gs, ag);
    depths: dict[str, int] = res[1];
    assert depths["top"] == 0;
    assert depths["bot"] == 2;
}
