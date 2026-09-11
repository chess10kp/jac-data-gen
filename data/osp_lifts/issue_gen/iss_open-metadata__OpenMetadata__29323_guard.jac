"""Bulk recursive service-entity deletes — open-metadata/OpenMetadata#29323."""

node Entity { has eid: str; has kind: str = ""; }
edge ChildOf {}

obj MetadataStore {
    has entities: dict[str, Entity] = {};
    has _root: Root;
    def init() { self._root = root; }
    def register_entity(eid: str, kind: str = "") -> None {
        if eid in self.entities { return; }
        e = Entity(eid=eid, kind=kind);
        self._root ++> e;
        self.entities[eid] = e;
    }
    def link_child(parent_id: str, child_id: str) -> None {
        p = self.entities.get(parent_id);
        c = self.entities.get(child_id);
        if p is None or c is None { return; }
        p +>:ChildOf:+> c;
    }
    def collect_delete_closure(root_id: str) -> list[str] {
        start = self.entities.get(root_id);
        if start is None { return []; }
        w = start spawn CollectDelete(claimed={});
        return w.found;
    }
    def bulk_delete(root_id: str) -> list[str] {
        start = self.entities.get(root_id);
        if start is None { return []; }
        w = start spawn CollectDelete(claimed={});
        for eid in w.found {
            n = self.entities.get(eid);
            if n is not None { del n; del self.entities[eid]; }
        }
        return sorted(w.found);
    }
    def exists(eid: str) -> bool { return eid in self.entities; }
    def children_of(eid: str) -> list[str] {
        n = self.entities.get(eid);
        if n is None { return []; }
        return sorted([c.eid for c in [n->:ChildOf:->]]);
    }
}

walker CollectDelete {
    has claimed: dict[str, bool];
    has found: list[str] = [];
    can step with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        self.found.append(here.eid);
        visit [->:ChildOf:->];
    }
}

def build_store() -> MetadataStore { return MetadataStore(); }

def _tree() -> MetadataStore {
    s = build_store();
    for (eid, kind) in [("svc", "service"), ("db", "database"), ("tbl", "table"), ("col", "column")] {
        s.register_entity(eid, kind);
    }
    s.link_child("svc", "db");
    s.link_child("db", "tbl");
    s.link_child("tbl", "col");
    return s;
}

def _diamond() -> MetadataStore {
    s = build_store();
    for eid in ["root", "left", "right", "join"] { s.register_entity(eid); }
    s.link_child("root", "left");
    s.link_child("root", "right");
    s.link_child("left", "join");
    s.link_child("right", "join");
    return s;
}

test "linear closure and bulk delete" {
    s = _tree();
    assert s.collect_delete_closure("svc") == ["svc", "db", "tbl", "col"];
    assert s.bulk_delete("db") == ["col", "db", "tbl"];
    assert s.exists("svc");
    assert not s.exists("tbl");
    assert s.children_of("svc") == [];
}

test "diamond adversarial multiset" {
    d = _diamond();
    assert sorted(d.collect_delete_closure("root")) == ["join", "left", "right", "root"];
    assert sorted(d.bulk_delete("root")) == ["join", "left", "right", "root"];
}

test "unknown root empty" {
    s = build_store();
    assert s.collect_delete_closure("missing") == [];
    assert s.bulk_delete("missing") == [];
}
