"""Lazialize/oasis#236 — Recursive OpenAPI callback operation lint walk."""

obj OpenApiDoc {
    has operations: dict[str, Operation] = {};
}

node Operation {
    has op_id: str;
}

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
