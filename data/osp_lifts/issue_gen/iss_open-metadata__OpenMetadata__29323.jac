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
            if n is not None {
                del n;
                del self.entities[eid];
            }
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
