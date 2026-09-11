"""skybristol/gkc#216 — Ontology seed dependency ordering workflow."""

node SeedEntity {
    has eid: str;
    has kind: str;
}

edge Requires {}

obj SeedStore {
    has entities: dict[str, SeedEntity] = {};
}

def load_seed(
    entities: list[tuple[str, str]],
    depends_edges: list[tuple[str, str]],
) -> SeedStore {
    ss = SeedStore();
    for (eid, kind) in entities {
        nd = SeedEntity(eid=eid, kind=kind);
        root ++> nd;
        ss.entities[eid] = nd;
    }
    for (entity, dep) in depends_edges {
        e = ss.entities.get(entity, None);
        d = ss.entities.get(dep, None);
        if e is not None and d is not None { e +>:Requires:+> d; }
    }
    return ss;
}

def dependency_order(store: SeedStore) -> list[str] {
    indeg: dict[str, int] = {};
    for k in store.entities.keys() { indeg[k] = 0; }
    for eid in store.entities.keys() {
        nd = store.entities[eid];
        for _ in [nd ->:Requires:->] {
            indeg[eid] = indeg[eid] + 1;
        }
    }
    queue: list[str] = [];
    for k in sorted(store.entities.keys()) {
        if indeg[k] == 0 { queue.append(k); }
    }
    order: list[str] = [];
    while len(queue) > 0 {
        u = queue.pop(0);
        order.append(u);
        for v in store.entities.keys() {
            vnd = store.entities[v];
            needs_u = False;
            for req in [vnd ->:Requires:->] {
                se: SeedEntity = req;
                if se.eid == u { needs_u = True; }
            }
            if needs_u {
                indeg[v] = indeg[v] - 1;
                if indeg[v] == 0 { queue.append(v); }
            }
        }
    }
    if len(order) != len(store.entities) { return []; }
    return order;
}

def detect_unresolved(store: SeedStore) -> list[str] {
    order = dependency_order(store);
    if len(order) == len(store.entities) { return []; }
    placed: dict[str, bool] = {};
    for o in order { placed[o] = True; }
    out: list[str] = [];
    for k in store.entities.keys() {
        if not (k in placed) { out.append(k); }
    }
    return sorted(out);
}

def entity_kind(store: SeedStore, entity_id: str) -> str | None {
    nd = store.entities.get(entity_id, None);
    if nd is None { return None; }
    return nd.kind;
}
