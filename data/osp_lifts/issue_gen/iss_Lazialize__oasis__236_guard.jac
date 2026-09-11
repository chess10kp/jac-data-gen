"""Guard: Lazialize/oasis#236."""

obj OpenApiDoc { has operations: dict[str, Operation] = {}; }
node Operation { has op_id: str; }
edge CallbackTo {}
edge RefTo {}

def _resolve_op(g: OpenApiDoc, op: Operation) -> Operation {
    cur = op;
    visiting: dict[str, bool] = {};
    while True {
        ref_targets = [cur ->:RefTo:->][?:Operation];
        if not ref_targets { break; }
        nxt = ref_targets[0];
        if nxt.op_id in visiting { break; }
        visiting[nxt.op_id] = True;
        cur = nxt;
    }
    return cur;
}

def load_openapi_doc(
    operations: list[str],
    callbacks: list[tuple[str, str]],
    refs: list[tuple[str, str]],
) -> OpenApiDoc {
    g = OpenApiDoc();
    for op in operations {
        if op not in g.operations {
            nd = Operation(op_id=op);
            root ++> nd;
            g.operations[op] = nd;
        }
    }
    for (owner, cb) in callbacks {
        a = g.operations.get(owner, None);
        b = g.operations.get(cb, None);
        if a is not None and b is not None { a +>:CallbackTo:+> b; }
    }
    for (src, dst) in refs {
        a = g.operations.get(src, None);
        b = g.operations.get(dst, None);
        if a is not None and b is not None { a +>:RefTo:+> b; }
    }
    return g;
}

def lint_reachable(g: OpenApiDoc, `root: str) -> list[str] {
    if `root not in g.operations { return []; }
    seen: dict[str, bool] = {};
    snap: list[str] = [`root];
    i = 0;
    while i < len(snap) {
        op_id = snap[i];
        i += 1;
        anchor = g.operations.get(op_id, None);
        if anchor is None { continue; }
        resolved = _resolve_op(g, anchor);
        rid = resolved.op_id;
        if rid in seen { continue; }
        seen[rid] = True;
        for cb in [resolved ->:CallbackTo:->][?:Operation] {
            if cb.op_id not in seen { snap.append(cb.op_id); }
        }
    }
    ids: list[str] = [];
    for op in seen.keys() { ids.append(op); }
    ids.sort();
    return ids;
}

test "callback chain lint coverage" {
    g = load_openapi_doc(
        ["paths.post", "cb.changed", "cb.notify"],
        [("paths.post", "cb.changed"), ("cb.changed", "cb.notify")],
        [],
    );
    assert lint_reachable(g, "paths.post") == [
        "cb.changed",
        "cb.notify",
        "paths.post",
    ];
}

test "cyclic callbacks terminate once" {
    g = load_openapi_doc(
        ["paths.post", "cb.a", "cb.b", "cb.c"],
        [
            ("paths.post", "cb.a"),
            ("cb.a", "cb.b"),
            ("cb.b", "cb.c"),
            ("cb.c", "cb.a"),
        ],
        [],
    );
    assert lint_reachable(g, "paths.post") == ["cb.a", "cb.b", "cb.c", "paths.post"];
}

test "diamond adversarial callback revisit" {
    g = load_openapi_doc(
        ["paths.post", "cb.left", "cb.right", "cb.leaf"],
        [
            ("paths.post", "cb.left"),
            ("paths.post", "cb.right"),
            ("cb.left", "cb.leaf"),
            ("cb.right", "cb.leaf"),
        ],
        [],
    );
    assert lint_reachable(g, "paths.post") == [
        "cb.leaf",
        "cb.left",
        "cb.right",
        "paths.post",
    ];
}

test "referenced callback resolves before lint" {
    g = load_openapi_doc(
        ["paths.post", "cb.inline", "cb.component"],
        [("paths.post", "cb.inline")],
        [("cb.inline", "cb.component")],
    );
    assert lint_reachable(g, "paths.post") == [
        "cb.component",
        "paths.post",
    ];
}

test "unknown root tolerant" {
    g = load_openapi_doc(["solo"], [], []);
    assert lint_reachable(g, "missing") == [];
}
