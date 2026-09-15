"""back2dos/tinkerbell#55 — toComplex infinite recursion with recursive constraints."""

node TypeNode {
    has tid: str;
    has label: str;
}

edge Constrains {}

def make_type(tid: str, label: str) -> TypeNode {
    nd = TypeNode(tid=tid, label=label);
    root ++> nd;
    return nd;
}

def attach_constraint(from_node: TypeNode, to_node: TypeNode) {
    from_node +>:Constrains:+> to_node;
}

walker ComplexWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has recursive_hits: list[str] = [];

    can step with TypeNode entry {
        if here.tid in self.claimed {
            self.recursive_hits.append(here.tid);
            print("recursive_skip:" + here.tid);
            skip;
        }
        self.claimed[here.tid] = True;
        self.order.append(here.tid);
        print("visit:" + here.tid);
        chs: list[TypeNode] = [here ->:Constrains:->][?:TypeNode];
        i: int = len(chs) - 1;
        while i >= 0 {
            visit :0: [chs[i]];
            i = i - 1;
        }
    }
}

def constraint_closure(type_id: str, store: dict[str, TypeNode]) -> list[str] {
    if type_id not in store {
        return [];
    }
    start = store[type_id];
    w = start spawn ComplexWalker(claimed={});
    print("closure_done:" + type_id);
    out: list[str] = [];
    for tid in w.order {
        out.append(tid);
    }
    return out;
}

def to_complex(type_id: str, store: dict[str, TypeNode]) -> dict[str, object] {
    if type_id not in store {
        return {"id": type_id, "label": "", "constraints": [], "recursive": []};
    }
    start = store[type_id];
    w = start spawn ComplexWalker(claimed={});
    print("complex_done:" + type_id);
    constraints: list[str] = [];
    j: int = 1;
    while j < len(w.order) {
        constraints.append(w.order[j]);
        j = j + 1;
    }
    rec: list[str] = [];
    for hit in w.recursive_hits {
        rec.append(hit);
    }
    rec = sorted(rec);
    return {
        "id": start.tid,
        "label": start.label,
        "constraints": constraints,
        "recursive": rec,
    };
}

test "closure_unknown_id" {
    store: dict[str, TypeNode] = {};
    got = constraint_closure("missing", store);
    assert len(got) == 0;
}

test "to_complex_unknown_id" {
    store: dict[str, TypeNode] = {};
    got = to_complex("missing", store);
    assert got["id"] == "missing";
    assert got["label"] == "";
    assert len(got["constraints"] as list) == 0;
    assert len(got["recursive"] as list) == 0;
}

test "closure_linear_chain" {
    a = make_type("a", "A");
    b = make_type("b", "B");
    attach_constraint(a, b);
    store: dict[str, TypeNode] = {};
    store["a"] = a;
    store["b"] = b;
    got = constraint_closure("a", store);
    assert got[0] == "a";
    assert got[1] == "b";
    assert len(got) == 2;
}

test "recursive_constraint_cycle" {
    x = make_type("x", "X");
    y = make_type("y", "Y");
    attach_constraint(x, y);
    attach_constraint(y, x);
    store: dict[str, TypeNode] = {};
    store["x"] = x;
    store["y"] = y;
    got = to_complex("x", store);
    rec = got["recursive"] as list;
    rec_sorted = sorted(rec);
    assert len(rec_sorted) >= 1;
}

test "to_complex_constraints_excludes_root" {
    p = make_type("p", "Parent");
    c = make_type("c", "Child");
    attach_constraint(p, c);
    store: dict[str, TypeNode] = {};
    store["p"] = p;
    store["c"] = c;
    out = to_complex("p", store);
    assert out["id"] == "p";
    assert out["label"] == "Parent";
    cons = out["constraints"] as list;
    assert cons[0] == "c";
    assert len(cons) == 1;
}
