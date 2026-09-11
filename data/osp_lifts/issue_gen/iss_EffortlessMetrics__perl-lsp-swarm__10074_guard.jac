"""Guard: EffortlessMetrics/perl-lsp-swarm#10074."""

obj SnapshotStore { has schema_id: str = ""; has root_nid: str = ""; has max_nodes: int = 256; }
node SyntaxNode { has nid: str; has kind: str; has start: int; has end: int; }
edge FieldRef { has slot: str; }

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has origin: str = "";
    can begin with Root entry {
        for n in [-->][?:SyntaxNode] { if n.nid == self.origin { visit [n]; } }
    }
    can step with SyntaxNode entry {
        if here.nid in self.claimed { skip; }
        self.claimed[here.nid] = True;
        if here.nid != self.origin { self.reached.append(here.nid); }
        visit [->:FieldRef:->] else { disengage; };
    }
    can finish with Root exit { report self.reached; }
}

walker BuildWalk {
    has claimed: dict[str, bool] = {};
    has ordered: list[str] = [];
    has origin: str = "";
    has cap: int = 256;
    has exceeded: bool = False;
    can begin with Root entry {
        for n in [-->][?:SyntaxNode] { if n.nid == self.origin { visit [n]; } }
    }
    can step with SyntaxNode entry {
        if self.exceeded { skip; }
        if here.nid in self.claimed { skip; }
        if len(self.ordered) >= self.cap { self.exceeded = True; skip; }
        self.claimed[here.nid] = True;
        self.ordered.append(here.nid);
        for (slot, child) in _child_fields(here) { visit [child]; }
    }
    can finish with Root exit { report self.ordered; }
}

def _pair_slot(p: tuple[str, SyntaxNode]) -> str { return p[0]; }

def _find(nid: str) -> SyntaxNode | None {
    for n in [-->][?:SyntaxNode] { if n.nid == nid { return n; } }
    return None;
}

def _child_fields(sn: SyntaxNode) -> list[tuple[str, SyntaxNode]] {
    pairs: list[tuple[str, SyntaxNode]] = [];
    for child in [sn ->:FieldRef:->][?:SyntaxNode] {
        slot = "";
        for e in [sn ->:FieldRef:-> child][?:FieldRef] { slot = e.slot; }
        pairs.append((slot, child));
    }
    return sorted(pairs, key=_pair_slot);
}

def load_snapshot(nodes: dict[str, dict], root_nid: str, schema_id: str, max_nodes: int = 256) -> SnapshotStore {
    mp: dict[str, SyntaxNode] = {};
    for nid in nodes {
        spec = nodes[nid];
        fresh = SyntaxNode(nid=nid, kind=spec.get("kind", ""), start=spec.get("start", 0), end=spec.get("end", 0));
        root ++> fresh;
        mp[nid] = fresh;
    }
    for nid in nodes {
        src = mp.get(nid, None);
        if src is None { continue; }
        for item in nodes[nid].get("refs", []) {
            tgt = mp.get(str(item[1]), None);
            if tgt is not None { src +>:FieldRef(slot=str(item[0])):+> tgt; }
        }
    }
    return SnapshotStore(schema_id=schema_id, root_nid=root_nid, max_nodes=max_nodes);
}

def field_reachable(g: SnapshotStore, start_nid: str) -> list[str] {
    _ = g;
    if _find(start_nid) is None { return []; }
    w = root spawn ReachWalk(claimed={}, reached=[], origin=start_nid);
    return sorted(w.reports[0] if w.reports else []);
}

def build_native_artifact(g: SnapshotStore) -> tuple[dict | None, str] {
    if _find(g.root_nid) is None { return (None, "invalid_snapshot"); }
    w = root spawn BuildWalk(claimed={}, ordered=[], origin=g.root_nid, cap=g.max_nodes, exceeded=False);
    if w.exceeded { return (None, "projection_limit_exceeded"); }
    ordered = w.reports[0] if w.reports else [];
    idx_map: dict[str, int] = {};
    for (i, nid) in enumerate(ordered) { idx_map[nid] = i; }
    table: list[dict] = [];
    for (i, nid) in enumerate(ordered) {
        n = _find(nid);
        if n is None { continue; }
        fields: list[tuple[str, int]] = [];
        for (slot, child) in _child_fields(n) { fields.append((slot, idx_map.get(child.nid, -1))); }
        table.append({"local_id": i, "kind": n.kind, "start": n.start, "end": n.end, "fields": fields});
    }
    return ({
        "schema_id": g.schema_id,
        "root": idx_map.get(g.root_nid, 0),
        "nodes": table,
        "disposition": "complete",
    }, "complete");
}

test "linear block projects field local ids" {
    nodes = {
        "prog": {"kind": "Block", "start": 0, "end": 20, "refs": [["body", "stmt_a"], ["tail", "stmt_b"]]},
        "stmt_a": {"kind": "Stmt", "start": 0, "end": 8, "refs": []},
        "stmt_b": {"kind": "Stmt", "start": 9, "end": 20, "refs": []},
    };
    g = load_snapshot(nodes, "prog", "native-proj-v1", 16);
    art, status = build_native_artifact(g);
    assert status == "complete";
    assert art is not None;
    assert art["root"] == 0;
    assert art["nodes"][0]["fields"] == [["body", 1], ["tail", 2]];
}

test "diamond adversarial revisit before deep cap" {
    nodes = {
        "hub": {"kind": "Block", "start": 0, "end": 30, "refs": [["left", "left"], ["right", "right"]]},
        "left": {"kind": "Stmt", "start": 0, "end": 10, "refs": [["to", "cap"]]},
        "right": {"kind": "Stmt", "start": 11, "end": 20, "refs": [["to", "cap"]]},
        "cap": {"kind": "Stmt", "start": 21, "end": 30, "refs": []},
    };
    g = load_snapshot(nodes, "hub", "native-proj-v1");
    assert field_reachable(g, "hub") == ["cap", "left", "right"];
}

test "ref cycle terminates once" {
    nodes = {
        "a": {"kind": "Loop", "start": 0, "end": 10, "refs": [["body", "b"]]},
        "b": {"kind": "Loop", "start": 1, "end": 9, "refs": [["next", "a"]]},
    };
    g = load_snapshot(nodes, "a", "native-proj-v1");
    assert field_reachable(g, "a") == ["b"];
}

test "projection limit returns no artifact" {
    nodes = {
        "prog": {"kind": "Block", "start": 0, "end": 20, "refs": [["body", "stmt_a"], ["tail", "stmt_b"]]},
        "stmt_a": {"kind": "Stmt", "start": 0, "end": 8, "refs": []},
        "stmt_b": {"kind": "Stmt", "start": 9, "end": 20, "refs": []},
    };
    g = load_snapshot(nodes, "prog", "native-proj-v1", 2);
    art, status = build_native_artifact(g);
    assert art is None;
    assert status == "projection_limit_exceeded";
}
