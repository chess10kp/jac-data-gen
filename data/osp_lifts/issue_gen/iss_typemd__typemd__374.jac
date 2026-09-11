"""typemd/typemd#374 — Single-hop relation field resolution."""

obj ObjectStore {
    has objects: dict[str, Entity] = {};
    has fields: dict[str, dict[str, str]] = {};
    has rel_targets: dict[str, dict[str, str]] = {};
}

node Entity { has oid: str; }
edge Relates { has rel_name: str = ""; }

def load_objects(
    entries: list[tuple[str, dict[str, str]]],
    relations: list[tuple[str, str, str | None]],
) -> ObjectStore {
    store = ObjectStore();
    for (oid, flds) in entries {
        if oid not in store.objects {
            nd = Entity(oid=oid);
            root ++> nd;
            store.objects[oid] = nd;
        }
        store.fields[oid] = flds;
        store.rel_targets[oid] = {};
    }
    for (src, rel_name, tgt) in relations {
        if tgt is None { continue; }
        a = store.objects.get(src, None);
        b = store.objects.get(tgt, None);
        if a is not None and b is not None {
            a +>:Relates(rel_name=rel_name):+> b;
            store.rel_targets[src][rel_name] = tgt;
        }
    }
    return store;
}

walker RelHop {
    has rel_name: str;
    has target_oid: str = "";
    has rel_index: dict[str, dict[str, str]] = {};

    can step with Entity entry {
        rels = self.rel_index.get(here.oid, {});
        if self.rel_name in rels { self.target_oid = rels[self.rel_name]; }
        disengage;
    }
}

def related_id(store: ObjectStore, obj_id: str, rel_name: str) -> str | None {
    src = store.objects.get(obj_id, None);
    if src is None { return None; }
    w = src spawn RelHop(rel_name=rel_name, target_oid="", rel_index=store.rel_targets);
    if w.target_oid == "" { return None; }
    if w.target_oid not in store.objects { return None; }
    return w.target_oid;
}

def resolve_field(store: ObjectStore, obj_id: str, dotted: str) -> str | None {
    if obj_id not in store.fields { return None; }
    parts = dotted.split(".", 1);
    if len(parts) == 1 { return store.fields[obj_id].get(parts[0], None); }
    tgt = related_id(store, obj_id, parts[0]);
    if tgt is None { return None; }
    return store.fields.get(tgt, {}).get(parts[1], None);
}

test "author.name resolves across relation" {
    store = load_objects(
        [("book1", {"title": "HP"}), ("person1", {"name": "Rowling", "bio": "author"})],
        [("book1", "author", "person1")],
    );
    assert resolve_field(store, "book1", "author.name") == "Rowling";
    assert resolve_field(store, "book1", "title") == "HP";
}

test "missing relation yields null" {
    store = load_objects([("book1", {"title": "HP"})], []);
    assert resolve_field(store, "book1", "author.name") is None;
}

test "deleted target yields null" {
    store = load_objects([("book1", {"title": "HP"})], [("book1", "author", "gone")]);
    assert resolve_field(store, "book1", "author.name") is None;
}
