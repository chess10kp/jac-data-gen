"""Guard: the-static-collective/the-haunted-toaster#121."""

obj ReceiptGraph { has receipts: dict[str, Receipt] = {}; }
node Receipt { has rid: str; }
edge Needs {}

def load_receipt_graph(
    receipt_ids: list[str],
    need_edges: list[tuple[str, str]],
) -> ReceiptGraph {
    g = ReceiptGraph();
    for rid in receipt_ids {
        if rid not in g.receipts {
            nd = Receipt(rid=rid);
            root ++> nd;
            g.receipts[rid] = nd;
        }
    }
    for (dep, receipt) in need_edges {
        a = g.receipts.get(dep, None);
        b = g.receipts.get(receipt, None);
        if a is not None and b is not None { a +>:Needs:+> b; }
    }
    return g;
}

def dependency_closure(g: ReceiptGraph, receipt_id: str) -> list[str] {
    if receipt_id not in g.receipts { return []; }
    claimed: dict[str, bool] = {receipt_id: True};
    snap: list[str] = [receipt_id];
    i = 0;
    while i < len(snap) {
        sid = snap[i];
        i += 1;
        anchor = g.receipts.get(sid, None);
        if anchor is None { continue; }
        for p in [anchor <-:Needs:<-][?:Receipt] {
            if p.rid not in claimed {
                claimed[p.rid] = True;
                snap.append(p.rid);
            }
        }
    }
    ids: list[str] = [];
    for rid in claimed.keys() { ids.append(rid); }
    ids.sort();
    return ids;
}

def unresolved(g: ReceiptGraph, resolved: list[str]) -> list[str] {
    done: dict[str, bool] = {};
    for r in resolved { done[r] = True; }
    pending: list[str] = [];
    for rid in g.receipts.keys() {
        if rid in done { continue; }
        deps = dependency_closure(g, rid);
        ok = True;
        for d in deps {
            if d != rid and d not in done { ok = False; }
        }
        if ok { pending.append(rid); }
    }
    pending.sort();
    return pending;
}

test "receipt reconstruction closure" {
    g = load_receipt_graph(
        ["render", "source_a", "source_b", "spec", "primitive"],
        [
            ("source_a", "render"),
            ("source_b", "render"),
            ("spec", "render"),
            ("primitive", "source_a"),
            ("primitive", "source_b"),
        ],
    );
    assert dependency_closure(g, "render") == [
        "primitive", "render", "source_a", "source_b", "spec",
    ];
    assert unresolved(g, ["primitive"]) == ["source_a", "source_b", "spec"];
    assert unresolved(g, ["primitive", "source_a", "source_b", "spec"]) == ["render"];
}

test "diamond adversarial closure" {
    g = load_receipt_graph(
        ["root", "left", "right", "join"],
        [("root", "left"), ("root", "right"), ("left", "join"), ("right", "join")],
    );
    assert dependency_closure(g, "join") == ["join", "left", "right", "root"];
}

test "unknown receipt tolerant" {
    g = load_receipt_graph(["solo"], []);
    assert dependency_closure(g, "ghost") == [];
}
