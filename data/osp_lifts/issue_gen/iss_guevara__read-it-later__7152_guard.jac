"""guevara/read-it-later#7152 — adjacency vs nested-set (MySQL EXPLAIN EXTENDED)."""

node HierNode {
    has name: str;
    has lft: int = 0;
    has rgt: int = 0;
}

edge ChildOf {}

obj HierarchyModel {
    has parent_of: dict[str, str | None] = {};
    has nodes: dict[str, HierNode] = {};
}

walker AdjDescWalk {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    has origin: str = "";

    can step with HierNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.origin { self.out.append(here.name); }
        children = [here ->:ChildOf:->][?:HierNode];
        nms: list[str] = [];
        for ch in children { nms.append(ch.name); }
        for nm in sorted(nms) {
            for ch in children {
                if ch.name == nm { visit ch; }
            }
        }
    }
}

def load_hierarchy(
    entries: list[tuple[str, int, int, str | None]],
) -> HierarchyModel {
    model = HierarchyModel();
    for (name, lft, rgt, parent) in entries {
        if parent is not None and not (parent in model.parent_of) {
            raise KeyError("unknown parent");
        }
        nd = model.nodes.get(name, None);
        if nd is None {
            nd = HierNode(name=name, lft=lft, rgt=rgt);
            root ++> nd;
            model.nodes[name] = nd;
        } else {
            nd.lft = lft;
            nd.rgt = rgt;
        }
        model.parent_of[name] = parent;
        if parent is not None {
            par = model.nodes.get(parent, None);
            if par is not None {
                exists = False;
                for ch in [par ->:ChildOf:->][?:HierNode] {
                    if ch.name == name { exists = True; }
                }
                if not exists { par +>:ChildOf:+> nd; }
            }
        }
    }
    return model;
}

def adj_session_descendants(model: HierarchyModel, `root: str) -> list[str] {
    if not (`root in model.parent_of) { return []; }
    nd = model.nodes.get(`root, None);
    if nd is None { return []; }
    w = nd spawn AdjDescWalk(claimed={}, out=[], origin=`root);
    return sorted(w.out);
}

def nested_spatial_subtree(model: HierarchyModel, `root: str) -> list[str] {
    nd = model.nodes.get(`root, None);
    if nd is None { return []; }
    lft = nd.lft;
    rgt = nd.rgt;
    out: list[str] = [];
    for name in model.nodes.keys() {
        if name == `root { continue; }
        n = model.nodes.get(name, None);
        if n is not None and n.lft >= lft and n.rgt <= rgt {
            out.append(name);
        }
    }
    return sorted(out);
}

def adj_session_depth(model: HierarchyModel, `node: str) -> int {
    if not (`node in model.parent_of) { return -1; }
    depth = 0;
    cur: str | None = `node;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur in seen { return -1; }
        seen[cur] = True;
        parent = model.parent_of.get(cur, None);
        if parent is None { break; }
        depth += 1;
        cur = parent;
    }
    return depth;
}

def nested_spatial_depth(model: HierarchyModel, `node: str) -> int {
    nd = model.nodes.get(`node, None);
    if nd is None { return -1; }
    nl = nd.lft;
    nr = nd.rgt;
    count = 0;
    for name in model.nodes.keys() {
        if name == `node { continue; }
        n = model.nodes.get(name, None);
        if n is not None and n.lft <= nl and n.rgt >= nr {
            count += 1;
        }
    }
    return count;
}

def models_agree_on_subtree(model: HierarchyModel, `root: str) -> bool {
    return adj_session_descendants(model, `root) == nested_spatial_subtree(model, `root);
}

test "ref harness parity on touching nested bounds" {
    m = load_hierarchy([
        ("root", 1, 10, None),
        ("a", 2, 5, "root"),
        ("b", 6, 9, "root"),
        ("a1", 3, 4, "a"),
        ("a2", 4, 5, "a"),
    ]);
    assert adj_session_descendants(m, "root") == ["a", "a1", "a2", "b"];;
    assert nested_spatial_subtree(m, "root") == ["a", "a1", "a2", "b"];;
    assert adj_session_descendants(m, "a") == ["a1", "a2"];;
    assert nested_spatial_subtree(m, "a") == ["a1", "a2"];;
    assert adj_session_depth(m, "a1") == 2;;
    assert nested_spatial_depth(m, "a1") == 2;;
    assert adj_session_depth(m, "a2") == 2;;
    assert nested_spatial_depth(m, "a2") == 2;;
    assert models_agree_on_subtree(m, "root") == True;;
    assert models_agree_on_subtree(m, "a") == True;;
    assert models_agree_on_subtree(m, "b") == True;;
}

test "ref harness shuffled insertion order" {
    m = load_hierarchy([
        ("root", 1, 12, None),
        ("right", 8, 11, "root"),
        ("left", 2, 7, "root"),
        ("join", 5, 6, "left"),
    ]);
    assert adj_session_descendants(m, "root") == ["join", "left", "right"];;
    assert nested_spatial_subtree(m, "root") == ["join", "left", "right"];;
    assert models_agree_on_subtree(m, "root") == True;;
    assert adj_session_descendants(m, "left") == ["join"];;
    assert nested_spatial_subtree(m, "left") == ["join"];;
}

test "diamond duplicate child enqueue adj closure" {
    m = load_hierarchy([
        ("root", 1, 10, None),
        ("left", 2, 5, "root"),
        ("right", 6, 9, "root"),
        ("sink", 3, 4, "left"),
        ("sink", 3, 4, "left"),
    ]);
    assert adj_session_descendants(m, "root") == ["left", "right", "sink"];;
    assert adj_session_descendants(m, "left") == ["sink"];;
    assert nested_spatial_subtree(m, "root") == ["left", "right", "sink"];;
    assert models_agree_on_subtree(m, "root") == True;;
}

test "unknown id tolerance across hierarchy queries" {
    m = load_hierarchy([("solo", 1, 2, None)]);
    assert adj_session_descendants(m, "ghost") == [];;
    assert nested_spatial_subtree(m, "ghost") == [];;
    assert adj_session_depth(m, "ghost") == -1;;
    assert nested_spatial_depth(m, "ghost") == -1;;
    assert models_agree_on_subtree(m, "ghost") == True;;
    assert adj_session_descendants(m, "solo") == [];;
    assert nested_spatial_subtree(m, "solo") == [];;
    assert adj_session_depth(m, "solo") == 0;;
    assert nested_spatial_depth(m, "solo") == 0;;
}

test "spatial containment excludes wide sibling bounds" {
    m = load_hierarchy([
        ("root", 1, 10, None),
        ("tight", 2, 5, "root"),
        ("wide", 4, 15, "root"),
    ]);
    assert adj_session_descendants(m, "root") == ["tight", "wide"];;
    assert nested_spatial_subtree(m, "root") == ["tight"];;
    assert models_agree_on_subtree(m, "root") == False;;
    assert nested_spatial_subtree(m, "tight") == [];;
}

test "parent cycle depth abort and descendant closure" {
    m = load_hierarchy([
        ("a", 1, 10, None),
        ("b", 2, 9, "a"),
        ("c", 3, 8, "b"),
        ("a", 1, 10, "c"),
    ]);
    assert adj_session_depth(m, "a") == -1;;
    assert adj_session_depth(m, "b") == -1;;
    assert adj_session_descendants(m, "a") == ["b", "c"];;
    assert nested_spatial_subtree(m, "a") == ["b", "c"];;
    assert models_agree_on_subtree(m, "a") == True;;
}

test "depth parity on nested interval chain" {
    m = load_hierarchy([
        ("root", 1, 12, None),
        ("mid", 2, 11, "root"),
        ("leaf", 3, 10, "mid"),
    ]);
    assert adj_session_depth(m, "leaf") == 2;;
    assert nested_spatial_depth(m, "leaf") == 2;;
    assert adj_session_depth(m, "root") == 0;;
    assert nested_spatial_depth(m, "root") == 0;;
    assert models_agree_on_subtree(m, "mid") == True;;
}

test "load rejects unknown parent before materialize" {
    try {
        load_hierarchy([("orphan", 1, 2, "missing")]);
        assert False;;
    } except KeyError {
        assert True;;
    }
}
