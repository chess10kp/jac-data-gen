"""lsst-sqre/ook#237 — Intersphinx entity hierarchy navigation."""

node Entity {
    has name: str;
    has role: str = "object";
}

edge ChildOf {}

obj EntityStore {
    has entities: dict[str, Entity] = {};
}

walker DescendWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Entity entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        visit [->:ChildOf:->][?:Entity];
    }
}

walker AscendWalk {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can step with Entity entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.chain.append(here.name);
        parents = [here <-:ChildOf:<-][?:Entity];
        if len(parents) == 0 { disengage; }
        visit [parents[0]];
    }
}

def load_entities(
    names: list[str],
    roles: list[tuple[str, str]],
    parent_edges: list[tuple[str, str]],
) -> EntityStore {
    store = EntityStore();
    for name in names {
        if name not in store.entities {
            nd = Entity(name=name);
            root ++> nd;
            store.entities[name] = nd;
        }
    }
    for (name, role) in roles {
        if name in store.entities { store.entities[name].role = role; }
    }
    for (child, parent) in parent_edges {
        c = store.entities.get(child, None);
        p = store.entities.get(parent, None);
        if c is not None and p is not None { p +>:ChildOf:+> c; }
    }
    return store;
}

def direct_children(store: EntityStore, name: str) -> list[str] {
    nd = store.entities.get(name, None);
    if nd is None { return []; }
    return sorted([e.name for e in [nd ->:ChildOf:->][?:Entity]]);
}

def all_descendants(store: EntityStore, name: str) -> list[str] {
    nd = store.entities.get(name, None);
    if nd is None { return []; }
    found: list[str] = [];
    claimed: dict[str, bool] = {name: True};
    for ch in [nd ->:ChildOf:->][?:Entity] {
        w = ch spawn DescendWalk(claimed=claimed, found=found);
        found = w.found;
        claimed = w.claimed;
    }
    return sorted(found);
}

def ancestor_chain(store: EntityStore, name: str) -> list[str] {
    nd = store.entities.get(name, None);
    if nd is None { return []; }
    w = nd spawn AscendWalk(claimed={}, chain=[]);
    anc = [n for n in w.chain if n != name];
    return list(reversed(anc));
}

def entity_role(store: EntityStore, name: str) -> str | None {
    nd = store.entities.get(name, None);
    if nd is None { return None; }
    return nd.role;
}