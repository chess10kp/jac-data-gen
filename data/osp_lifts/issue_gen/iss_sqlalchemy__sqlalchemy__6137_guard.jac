"""Self-referential M2M back-populate — sqlalchemy/sqlalchemy#6137."""

node GraphRoot {}

node Entity {
    has cid: str;
    has kind: str;
}

edge Membership {}

edge Neighbor {}

walker NeighborClosure {
    has claimed: dict[str, bool] = {};
    has start_id: str = "";
    has found: list[str] = [];

    can begin with GraphRoot entry {
        for ent in [here ->:Membership:->][?:Entity] {
            if ent.cid == self.start_id {
                visit ent;
            }
        }
        print {"walker": "NeighborClosure", "start": self.start_id, "found": len(self.found)};
    }

    can walk with Entity entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid != self.start_id {
            self.found.append(here.cid);
        }
        kids: list[Entity] = [here ->:Neighbor:->][?:Entity];
        visit :0: kids;
    }
}

def new_graph -> GraphRoot {
    gr = GraphRoot();
    return gr;
}

def _find_entity(graph_root: GraphRoot, node_id: str) -> Entity | None {
    for ent in [graph_root ->:Membership:->][?:Entity] {
        if ent.cid == node_id {
            return ent;
        }
    }
    return None;
}

def create_entity(graph_root: GraphRoot, kind: str) -> str {
    count: int = 0;
    for ent in [graph_root ->:Membership:->][?:Entity] {
        count = count + 1;
    }
    cid: str = "e" + str(count);
    ent = Entity(cid=cid, kind=kind);
    graph_root +>:Membership:+> ent;
    return cid;
}

def connect_neighbors(graph_root: GraphRoot, a_id: str, b_id: str) -> bool {
    if a_id == b_id {
        return False;
    }
    a = _find_entity(graph_root, a_id);
    b = _find_entity(graph_root, b_id);
    if a is None or b is None {
        return False;
    }
    a +>:Neighbor:+> b;
    b +>:Neighbor:+> a;
    return True;
}

def get_neighbors(graph_root: GraphRoot, node_id: str) -> list[str] {
    target = _find_entity(graph_root, node_id);
    if target is None {
        return [];
    }
    ids: list[str] = [];
    for n in [target ->:Neighbor:->][?:Entity] {
        ids.append(n.cid);
    }
    return sorted(ids);
}

def disconnect_neighbors(graph_root: GraphRoot, a_id: str, b_id: str) -> bool {
    a = _find_entity(graph_root, a_id);
    b = _find_entity(graph_root, b_id);
    if a is None or b is None {
        return False;
    }
    for peer in [a ->:Neighbor:->][?:Entity] {
        if peer.cid == b_id {
            peer disconnect from a;
        }
    }
    for peer in [b ->:Neighbor:->][?:Entity] {
        if peer.cid == a_id {
            peer disconnect from b;
        }
    }
    return True;
}

def neighbor_closure(graph_root: GraphRoot, start_id: str) -> list[str] {
    w = graph_root spawn NeighborClosure(claimed={}, start_id=start_id, found=[]);
    out: list[str] = [];
    for x in w.found {
        out.append(x);
    }
    return sorted(out);
}

test "create_and_connect" {
    gr = new_graph();
    a = create_entity(gr, "user");
    b = create_entity(gr, "user");
    c = create_entity(gr, "user");
    assert connect_neighbors(gr, a, b);
    assert connect_neighbors(gr, b, c);
    assert get_neighbors(gr, a) == ["e1"];
    assert get_neighbors(gr, b) == ["e0", "e2"];
    assert neighbor_closure(gr, a) == ["e1", "e2"];
}

test "self_connect_rejected" {
    gr = new_graph();
    a = create_entity(gr, "user");
    assert connect_neighbors(gr, a, a) == False;
    assert get_neighbors(gr, a) == [];
}

test "missing_node_tolerance" {
    gr = new_graph();
    a = create_entity(gr, "user");
    assert connect_neighbors(gr, a, "missing") == False;
    assert get_neighbors(gr, "missing") == [];
    assert neighbor_closure(gr, "missing") == [];
}

test "disconnect_bidirectional" {
    gr = new_graph();
    a = create_entity(gr, "user");
    b = create_entity(gr, "user");
    assert connect_neighbors(gr, a, b);
    assert disconnect_neighbors(gr, a, b);
    assert get_neighbors(gr, a) == [];
    assert get_neighbors(gr, b) == [];
    assert neighbor_closure(gr, a) == [];
}

test "cycle_closure_once_only" {
    gr = new_graph();
    a = create_entity(gr, "user");
    b = create_entity(gr, "user");
    c = create_entity(gr, "user");
    assert connect_neighbors(gr, a, b);
    assert connect_neighbors(gr, b, c);
    assert connect_neighbors(gr, c, a);
    assert neighbor_closure(gr, a) == ["e1", "e2"];
}
