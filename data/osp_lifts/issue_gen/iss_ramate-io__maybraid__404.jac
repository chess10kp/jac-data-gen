"""ramate-io/maybraid#404 — MultiMesh ChildOf hierarchy validation."""

node Entity {
    has eid: str;
}

edge ChildOf {}

obj MeshStore {
    has entities: dict[str, Entity] = {};
}

walker DescWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has anchor: str = "";

    can step with Entity entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        if here.eid != self.anchor {
            self.found.append(here.eid);
        }
        visit [->:ChildOf:->][?:Entity];
    }
}

walker ParentWalk {
    has claimed: dict[str, bool] = {};
    has cyclic: bool = False;

    can step with Entity entry {
        if here.eid in self.claimed {
            self.cyclic = True;
            disengage;
        }
        self.claimed[here.eid] = True;
        visit [<-:ChildOf:<-][?:Entity];
    }
}

def load_mesh(
    entity_ids: list[str],
    child_of_edges: list[tuple[str, str]],
) -> MeshStore {
    ms = MeshStore();
    for eid in entity_ids {
        nd = Entity(eid=eid);
        root ++> nd;
        ms.entities[eid] = nd;
    }
    for (parent, child) in child_of_edges {
        p = ms.entities.get(parent, None);
        c = ms.entities.get(child, None);
        if p is not None and c is not None { p +>:ChildOf:+> c; }
    }
    return ms;
}

def descendants(store: MeshStore, entity: str) -> list[str] {
    nd = store.entities.get(entity, None);
    if nd is None { return []; }
    w = nd spawn DescWalk(claimed={}, anchor=entity);
    return sorted(w.found);
}

def validate_no_cycles(store: MeshStore) -> bool {
    for eid in store.entities {
        nd = store.entities[eid];
        w = nd spawn ParentWalk(claimed={});
        if w.cyclic { return False; }
    }
    return True;
}

def member_count(store: MeshStore, `root: str) -> int {
    if `root not in store.entities { return 0; }
    return len(descendants(store, `root)) + 1;
}
