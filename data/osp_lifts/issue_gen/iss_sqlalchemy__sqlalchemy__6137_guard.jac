"""sqlalchemy/sqlalchemy#6137"""

node Entity {
    has cid: str;
    has polymorph: str;
}

edge Neighbor {}

def _nodes(st: dict[str, object]) -> dict[str, object] {
    return st["nodes"] as dict[str, object];
}

def new_store() -> dict[str, object] {
    st: dict[str, object] = {};
    st["nodes"] = {};
    return st;
}

def create_entity(st: dict[str, object], polymorph: str) -> str {
    nodes = _nodes(st);
    cid = "e" + str(len(nodes));
    nd = Entity(cid=cid, polymorph=polymorph);
    root ++> nd;
    nodes[cid] = nd;
    return cid;
}

def _get(st: dict[str, object], node_id: str) -> object {
    nodes = _nodes(st);
    if node_id not in nodes {
        return None;
    }
    return nodes[node_id];
}

def _has_neighbor(a: Entity, b_id: str) -> bool {
    for ch in [a ->:Neighbor:->][?:Entity] {
        if ch.cid == b_id {
            return True;
        }
    }
    return False;
}

def link_neighbors(st: dict[str, object], left_id: str, right_id: str) -> None {
    left_obj = _get(st, left_id);
    right_obj = _get(st, right_id);
    if left_obj is None or right_obj is None {
        return;
    }
    left = left_obj as Entity;
    right = right_obj as Entity;
    if not _has_neighbor(left, right.cid) {
        left +>:Neighbor:+> right;
    }
    if not _has_neighbor(right, left.cid) {
        right +>:Neighbor:+> left;
    }
}

def neighbor_ids(st: dict[str, object], node_id: str) -> list[str] {
    nd_obj = _get(st, node_id);
    if nd_obj is None {
        return [];
    }
    nd = nd_obj as Entity;
    out: list[str] = [];
    for ch in [nd ->:Neighbor:->][?:Entity] {
        out.append(ch.cid);
    }
    return sorted(out);
}

def back_populated(st: dict[str, object], left_id: str, right_id: str) -> bool {
    left_obj = _get(st, left_id);
    right_obj = _get(st, right_id);
    if left_obj is None or right_obj is None {
        return False;
    }
    left = left_obj as Entity;
    right = right_obj as Entity;
    return _has_neighbor(left, right.cid) and _has_neighbor(right, left.cid);
}

walker CompWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step_entity with Entity entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print({"comp": here.cid});
        kids: list[Entity] = [];
        for ch in [here ->:Neighbor:->][?:Entity] {
            kids.append(ch);
        }
        visit :0: kids else {
            disengage;
        }
    }
}

def connected_component(st: dict[str, object], start_id: str) -> list[str] {
    start_obj = _get(st, start_id);
    if start_obj is None {
        return [];
    }
    start = start_obj as Entity;
    w = start spawn CompWalker(claimed={});
    out: list[str] = [];
    for cid in w.found {
        out.append(cid);
    }
    return sorted(out);
}

test "back_populated_symmetric" {
    st = new_store();
    left_id = create_entity(st, "tag");
    right_id = create_entity(st, "tag");
    link_neighbors(st, left_id, right_id);
    assert back_populated(st, left_id, right_id);
    assert back_populated(st, right_id, left_id);
}

test "neighbor_ids_sorted" {
    st = new_store();
    a = create_entity(st, "tag");
    b = create_entity(st, "tag");
    c = create_entity(st, "tag");
    link_neighbors(st, a, b);
    link_neighbors(st, c, a);
    assert neighbor_ids(st, a) == sorted([b, c]);
}

test "unknown_ids_tolerated" {
    st = new_store();
    assert neighbor_ids(st, "missing") == [];
    assert connected_component(st, "missing") == [];
    assert back_populated(st, "missing", "also_missing") == False;
}

test "diamond_revisit_component" {
    st = new_store();
    a = create_entity(st, "tag");
    b = create_entity(st, "tag");
    c = create_entity(st, "tag");
    d = create_entity(st, "tag");
    link_neighbors(st, a, b);
    link_neighbors(st, a, c);
    link_neighbors(st, c, d);
    link_neighbors(st, b, d);
    comp = connected_component(st, a);
    expected: list[str] = sorted([a, b, c, d]);
    assert comp == expected;
    assert len(comp) == 4;
}

test "isolated_component" {
    st = new_store();
    lone = create_entity(st, "tag");
    other = create_entity(st, "tag");
    assert connected_component(st, lone) == [lone];
    assert neighbor_ids(st, other) == [];
}
