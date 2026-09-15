"""styk-tv/pgRDF#6 — transitive subclass closure for type carving."""

node Type {
    has tid: str;
    has cid: str = "";
}

edge SubClassOf {}

walker SubtypeWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can boot with root entry {
        print("boot", "subclass_closure");
        seeds: list[Type] = [here ->][?:Type];
        if len(seeds) > 0 {
            for nd in seeds {
                visit :0: [nd];
            }
        } else {
            disengage;
        }
    }

    can collect with Type entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.tid);
        print("collect", here.tid);
        subs: list[Type] = [here <-:SubClassOf:->][?:Type];
        if len(subs) > 0 {
            for sub in subs {
                visit :0: [sub];
            }
        } else {
            disengage;
        }
    }
}

def _ensure_type(graph_root: Type, store: dict[str, Type], tid: str) -> Type {
    if tid in store {
        return store[tid];
    }
    nd = Type(tid=tid, cid=tid);
    graph_root ++> nd;
    store[tid] = nd;
    return nd;
}

def build_subclass_children(edges: list[tuple[str, str]]) -> dict[str, list[str]] {
    children: dict[str, list[str]] = {};
    for pair in edges {
        sub = pair[0];
        sup = pair[1];
        if sup not in children {
            children[sup] = [];
        }
        children[sup].append(sub);
    }
    for sup in children {
        children[sup] = sorted(children[sup]);
    }
    return children;
}

def transitive_subtypes(children_map: dict[str, list[str]], anchor: str) -> list[str] {
    graph_root = Type(tid="__hroot__", cid="__hroot__");
    store: dict[str, Type] = {};
    _ensure_type(graph_root, store, anchor);
    for sup in children_map {
        sup_nd = _ensure_type(graph_root, store, sup);
        subs = children_map[sup];
        for sub_tid in subs {
            sub_nd = _ensure_type(graph_root, store, sub_tid);
            sub_nd +>:SubClassOf:+> sup_nd;
        }
    }
    anchor_nd = store[anchor] as Type;
    w = anchor_nd spawn SubtypeWalker(claimed={});
    return sorted(w.found);
}

def expand_carve_anchors(
    children_map: dict[str, list[str]],
    anchors: list[str],
    include_subclasses: bool = True,
) -> list[str] {
    acc: dict[str, bool] = {};
    sorted_anchors = sorted(anchors);
    if include_subclasses {
        for a in sorted_anchors {
            part = transitive_subtypes(children_map, a);
            for t in part {
                acc[t] = True;
            }
        }
    } else {
        for a in sorted_anchors {
            acc[a] = True;
        }
    }
    out: list[str] = [];
    for k in acc {
        out.append(k);
    }
    return sorted(out);
}

def type_allowed_for_carve(entity_type: str, expanded: list[str]) -> bool {
    for t in expanded {
        if t == entity_type {
            return True;
        }
    }
    return False;
}

with entry {
    anchor = Type(tid="Q3918", cid="Q3918");
    root ++> anchor;
    pub = Type(tid="Q875538", cid="Q875538");
    root ++> pub;
    pub +>:SubClassOf:+> anchor;
    root spawn SubtypeWalker(claimed={});
}

test "build_subclass_children_sorted" {
    children = build_subclass_children([("Q875538", "Q3918"), ("Q123", "Q3918")]);
    assert children["Q3918"] == ["Q123", "Q875538"];;
}

test "transitive_subtypes_closure" {
    children = build_subclass_children([("Q875538", "Q3918"), ("Q123", "Q875538")]);
    got = transitive_subtypes(children, "Q3918");
    assert got == ["Q123", "Q3918", "Q875538"];;
}

test "expand_carve_with_subclasses" {
    children = build_subclass_children([("Q875538", "Q3918"), ("Q123", "Q875538")]);
    got = expand_carve_anchors(children, ["Q3918"], include_subclasses=True);
    assert got == ["Q123", "Q3918", "Q875538"];;
}

test "expand_carve_without_subclasses" {
    children = build_subclass_children([("Q875538", "Q3918")]);
    got = expand_carve_anchors(children, ["Q3918", "Q999"], include_subclasses=False);
    assert got == ["Q3918", "Q999"];;
}

test "type_allowed_for_carve_positive" {
    expanded = expand_carve_anchors(
        build_subclass_children([("Q875538", "Q3918")]),
        ["Q3918"],
        include_subclasses=True,
    );
    assert type_allowed_for_carve("Q875538", expanded) == True;;
}

test "type_allowed_for_carve_negative" {
    expanded = ["Q3918", "Q875538"];
    assert type_allowed_for_carve("Q999", expanded) == False;;
}
