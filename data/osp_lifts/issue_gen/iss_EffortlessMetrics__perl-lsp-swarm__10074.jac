"""EffortlessMetrics/perl-lsp-swarm#10074 — native syntax artifact (OSP lift)."""

obj SnapshotStore {
    has schema_id: str = "";
    has root_nid: str = "";
    has max_nodes: int = 256;
}

node SyntaxNode {
    has nid: str;
    has kind: str;
    has start: int;
    has end: int;
}

edge FieldRef {
    has slot: str;
}

walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has origin: str = "";

    can begin with Root entry {
        for n in [-->][?:SyntaxNode] {
            if n.nid == self.origin {
                visit [n];
            }
        }
    }

    can step with SyntaxNode entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        if here.nid != self.origin {
            self.reached.append(here.nid);
        }
        visit [->:FieldRef:->] else { disengage; };
    }

    can finish with Root exit {
        report self.reached;
    }
}

walker BuildWalk {
    has claimed: dict[str, bool] = {};
    has ordered: list[str] = [];
    has origin: str = "";
    has cap: int = 256;
    has exceeded: bool = False;

    can begin with Root entry {
        for n in [-->][?:SyntaxNode] {
            if n.nid == self.origin {
                visit [n];
            }
        }
    }

    can step with SyntaxNode entry {
        if self.exceeded {
            skip;
        }
        if here.nid in self.claimed {
            skip;
        }
        if len(self.ordered) >= self.cap {
            self.exceeded = True;
            skip;
        }
        self.claimed[here.nid] = True;
        self.ordered.append(here.nid);
        for (slot, child) in _child_fields(here) {
            visit [child];
        }
    }

    can finish with Root exit {
        report self.ordered;
    }
}

def _pair_slot(p: tuple[str, SyntaxNode]) -> str {
    return p[0];
}

def _find(nid: str) -> SyntaxNode | None {
    for n in [-->][?:SyntaxNode] {
        if n.nid == nid {
            return n;
        }
    }
    return None;
}

def _child_fields(sn: SyntaxNode) -> list[tuple[str, SyntaxNode]] {
    pairs: list[tuple[str, SyntaxNode]] = [];
    for child in [sn ->:FieldRef:->][?:SyntaxNode] {
        slot = "";
        for e in [sn ->:FieldRef:-> child][?:FieldRef] {
            slot = e.slot;
        }
        pairs.append((slot, child));
    }
    return sorted(pairs, key=_pair_slot);
}

def load_snapshot(
    nodes: dict[str, dict],
    root_nid: str,
    schema_id: str,
    max_nodes: int = 256,
) -> SnapshotStore {
    mp: dict[str, SyntaxNode] = {};
    for nid in nodes {
        spec = nodes[nid];
        fresh = SyntaxNode(
            nid=nid,
            kind=spec.get("kind", ""),
            start=spec.get("start", 0),
            end=spec.get("end", 0),
        );
        root ++> fresh;
        mp[nid] = fresh;
    }
    for nid in nodes {
        src = mp.get(nid, None);
        if src is None {
            continue;
        }
        spec = nodes[nid];
        refs = spec.get("refs", []);
        for item in refs {
            slot = str(item[0]);
            tgt_id = str(item[1]);
            tgt = mp.get(tgt_id, None);
            if tgt is not None {
                src +>:FieldRef(slot=slot):+> tgt;
            }
        }
    }
    return SnapshotStore(schema_id=schema_id, root_nid=root_nid, max_nodes=max_nodes);
}

def field_reachable(g: SnapshotStore, start_nid: str) -> list[str] {
    _ = g;
    if _find(start_nid) is None {
        return [];
    }
    w = root spawn ReachWalk(claimed={}, reached=[], origin=start_nid);
    raw = w.reports[0] if w.reports else [];
    return sorted(raw);
}

def build_native_artifact(g: SnapshotStore) -> tuple[dict | None, str] {
    if _find(g.root_nid) is None {
        return (None, "invalid_snapshot");
    }
    w = root spawn BuildWalk(
        claimed={},
        ordered=[],
        origin=g.root_nid,
        cap=g.max_nodes,
        exceeded=False,
    );
    if w.exceeded {
        return (None, "projection_limit_exceeded");
    }
    ordered = w.reports[0] if w.reports else [];
    idx_map: dict[str, int] = {};
    for (i, nid) in enumerate(ordered) {
        idx_map[nid] = i;
    }
    table: list[dict] = [];
    for (i, nid) in enumerate(ordered) {
        n = _find(nid);
        if n is None {
            continue;
        }
        fields: list[tuple[str, int]] = [];
        for (slot, child) in _child_fields(n) {
            fields.append((slot, idx_map.get(child.nid, -1)));
        }
        table.append({
            "local_id": i,
            "kind": n.kind,
            "start": n.start,
            "end": n.end,
            "fields": fields,
        });
    }
    artifact = {
        "schema_id": g.schema_id,
        "root": idx_map.get(g.root_nid, 0),
        "nodes": table,
        "disposition": "complete",
    };
    return (artifact, "complete");
}
