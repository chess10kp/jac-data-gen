"""khalilbenaz/khalilbenaz.github.io#214 — Datalog-style ancestor transitive closure."""

node Person {
    has name: str;
}

edge ParentOf {}

obj PersonStore {
    has people: dict[str, Person] = {};
}

walker AncestorCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Person entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        parents = [here <-:ParentOf:<-][?:Person];
        if len(parents) == 0 { disengage; }
        visit [parents[0]];
    }
}

def load_people(names: list[str], parent_edges: list[tuple[str, str]]) -> PersonStore {
    store = PersonStore();
    for name in names {
        if name not in store.people {
            nd = Person(name=name);
            root ++> nd;
            store.people[name] = nd;
        }
    }
    for (child, parent) in parent_edges {
        c = store.people.get(child, None);
        p = store.people.get(parent, None);
        if c is not None and p is not None { p +>:ParentOf:+> c; }
    }
    return store;
}

def ancestors_of(store: PersonStore, person: str) -> list[str] {
    nd = store.people.get(person, None);
    if nd is None { return []; }
    parents = [nd <-:ParentOf:<-][?:Person];
    if len(parents) == 0 { return []; }
    found: list[str] = [];
    claimed: dict[str, bool] = {person: True};
    for p in parents {
        w = p spawn AncestorCollect(claimed=claimed, found=found);
        found = w.found;
        claimed = w.claimed;
    }
    return sorted(found);
}

def is_ancestor(store: PersonStore, ancestor: str, person: str) -> bool {
    return ancestor in ancestors_of(store, person);
}

def parent_of(store: PersonStore, person: str) -> str | None {
    nd = store.people.get(person, None);
    if nd is None { return None; }
    parents = [nd <-:ParentOf:<-][?:Person];
    if len(parents) == 0 { return None; }
    return parents[0].name;
}
