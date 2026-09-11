"""erraggy/oastools#488 — cycle-safe schema DeepCopy (OSP lift)."""

obj SchemaStore {
    has nodes: dict[str, dict] = {};
    has refs: list[tuple[str, str, str]] = [];
}

node SchemaPart {
    has sid: str;
    has kind: str;
}

edge SchemaRef {
    has field: str;
}

walker RefCloseWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has origin: str = "";

    can step with SchemaPart entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        if here.sid != self.origin { self.reached.append(here.sid); }
        visit [->:SchemaRef:->] else { disengage; };
    }
}

walker CopyOrderWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with SchemaPart entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.order.append(here.sid);
        visit [->:SchemaRef:->] else { disengage; };
    }
}

def _find(sid: str) -> SchemaPart | None {
    for n in [-->][?:SchemaPart] {
        if n.sid == sid { return n; }
    }
    return None;
}

def load_schema(
    nodes: list[tuple[str, str]],
    refs: list[tuple[str, str, str]],
) -> SchemaStore {
    mp: dict[str, SchemaPart] = {};
    for (sid, kind) in nodes {
        if sid not in mp {
            fresh = SchemaPart(sid=sid, kind=kind);
            root ++> fresh;
            mp[sid] = fresh;
        }
    }
    for (src, field, tgt) in refs {
        a = mp.get(src, None);
        b = mp.get(tgt, None);
        if a is not None and b is not None {
            a +>:SchemaRef(field=field):+> b;
        }
    }
    node_specs: dict[str, dict] = {};
    for (sid, kind) in nodes {
        node_specs[sid] = {"kind": kind};
    }
    return SchemaStore(nodes=node_specs, refs=refs);
}

def ref_closure(g: SchemaStore, root_id: str) -> list[str] {
    if root_id not in g.nodes { return []; }
    anchor = _find(root_id);
    if anchor is None { return []; }
    w = anchor spawn RefCloseWalk(claimed={}, reached=[], origin=root_id);
    return sorted(w.reached);
}

def deep_copy(g: SchemaStore, root_id: str) -> dict {
    if root_id not in g.nodes { return {}; }
    anchor = _find(root_id);
    if anchor is None { return {}; }
    w = anchor spawn CopyOrderWalk(claimed={}, order=[]);
    copies: dict[str, dict] = {};
    for sid in w.order {
        spec = g.nodes.get(sid, None);
        if spec is not None {
            copies[sid] = {"kind": spec["kind"], "props": {}};
        }
    }
    for (src, field, tgt) in g.refs {
        sc = copies.get(src, None);
        tc = copies.get(tgt, None);
        if sc is not None and tc is not None {
            sc["props"][field] = tc;
        }
    }
    out = copies.get(root_id, None);
    if out is None { return {}; }
    return out;
}
