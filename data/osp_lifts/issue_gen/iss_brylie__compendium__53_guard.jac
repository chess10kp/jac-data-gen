"""brylie/compendium#53 — Relationship and provenance edge fabric."""

node Entity {
    has eid: str;
}

edge References {}
edge DerivesFrom {}
edge Supersedes {}

obj RelationStore {
    has entities: dict[str, Entity] = {};
    has retired: dict[str, bool] = {};
}

def _edge_key(source: str, target: str, rel_type: str) -> str {
    return source + "|" + target + "|" + rel_type;
}

def load_entities(entity_ids: list[str]) -> RelationStore {
    rs = RelationStore();
    for eid in entity_ids {
        nd = Entity(eid=eid);
        root ++> nd;
        rs.entities[eid] = nd;
    }
    return rs;
}

def create_ref(
    store: RelationStore,
    source: str,
    target: str,
    rel_type: str,
) -> bool {
    src = store.entities.get(source, None);
    tgt = store.entities.get(target, None);
    if src is None or tgt is None { return False; }
    key = _edge_key(source, target, rel_type);
    if key in store.retired { store.retired.pop(key); }
    if rel_type == "references" { src +>:References:+> tgt; }
    elif rel_type == "derives_from" { src +>:DerivesFrom:+> tgt; }
    elif rel_type == "supersedes" { src +>:Supersedes:+> tgt; }
    else { return False; }
    return True;
}

def forward_refs(store: RelationStore, source: str) -> list[tuple[str, str]] {
    nd = store.entities.get(source, None);
    if nd is None { return []; }
    out: list[tuple[str, str]] = [];
    for t in [nd ->:References:->] {
        e: Entity = t;
        key = _edge_key(source, e.eid, "references");
        if not (key in store.retired) { out.append((e.eid, "references")); }
    }
    for t in [nd ->:DerivesFrom:->] {
        e: Entity = t;
        key = _edge_key(source, e.eid, "derives_from");
        if not (key in store.retired) { out.append((e.eid, "derives_from")); }
    }
    for t in [nd ->:Supersedes:->] {
        e: Entity = t;
        key = _edge_key(source, e.eid, "supersedes");
        if not (key in store.retired) { out.append((e.eid, "supersedes")); }
    }
    return sorted(out);
}

def reverse_refs(store: RelationStore, target: str) -> list[tuple[str, str]] {
    nd = store.entities.get(target, None);
    if nd is None { return []; }
    out: list[tuple[str, str]] = [];
    for s in [nd <-:References:<-][?:Entity] {
        key = _edge_key(s.eid, target, "references");
        if not (key in store.retired) { out.append((s.eid, "references")); }
    }
    for s in [nd <-:DerivesFrom:<-][?:Entity] {
        key = _edge_key(s.eid, target, "derives_from");
        if not (key in store.retired) { out.append((s.eid, "derives_from")); }
    }
    for s in [nd <-:Supersedes:<-][?:Entity] {
        key = _edge_key(s.eid, target, "supersedes");
        if not (key in store.retired) { out.append((s.eid, "supersedes")); }
    }
    return sorted(out);
}

def retire_ref(
    store: RelationStore,
    source: str,
    target: str,
    rel_type: str,
) -> bool {
    fwd = forward_refs(store, source);
    found = False;
    for (t, r) in fwd {
        if t == target and r == rel_type { found = True; }
    }
    if not found { return False; }
    store.retired[_edge_key(source, target, rel_type)] = True;
    return True;
}

test "forward and reverse refs" {
    rs = load_entities(["doc_a", "doc_b", "doc_c"]);
    create_ref(rs, "doc_a", "doc_b", "references");
    create_ref(rs, "doc_c", "doc_a", "derives_from");
    assert forward_refs(rs, "doc_a") == [("doc_b", "references")];
    assert reverse_refs(rs, "doc_a") == [("doc_c", "derives_from")];
    retire_ref(rs, "doc_a", "doc_b", "references");
    assert forward_refs(rs, "doc_a") == [];
    assert forward_refs(rs, "ghost") == [];
}
