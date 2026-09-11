"""khalilbenaz/khalilbenaz.github.io#214 — Datalog-style ancestor transitive closure."""
import from __future__ { annotations }
class PersonStore {
    def init(self: PersonStore) -> None {
        self._people: set[str] = `set();
        self._parent: dict[(str, (str | None))] = {};
    }
}
def load_people(
    names: list[str], parent_edges: list[tuple[(str, str)]]
) -> PersonStore {
    store = PersonStore();
    for name in names {
        store._people.add(name);
        store._parent[name] = None;
    }
    for (child, parent) in parent_edges {
        if ((child in store._people) and (parent in store._people)) {
            store._parent[child] = parent;
        }
    }
    return store;
}
def _walk_ancestors(store: PersonStore, person: str, seen: set[str]) -> list[str] {
    hits: list[str] = [];
    cur: (str | None) = person;
    while (cur is not None) {
        parent = store._parent.get(cur);
        if ((parent is None) or (parent in seen)) {
            break;
        }
        seen.add(parent);
        hits.append(parent);
        cur = parent;
    }
    return hits;
}
def ancestors_of(store: PersonStore, person: str) -> list[str] {
    if (person not in store._people) {
        return [];
    }
    direct = store._parent.get(person);
    if (direct is None) {
        return [];
    }
    seen: set[str] = {person};
    all_anc: set[str] = `set();
    stack = [direct];
    while stack {
        cur = stack.pop();
        if (cur in seen) {
            continue;
        }
        seen.add(cur);
        all_anc.add(cur);
        parent = store._parent.get(cur);
        if ((parent is not None) and (parent not in seen)) {
            stack.append(parent);
        }
    }
    return sorted(all_anc);
}
def is_ancestor(store: PersonStore, ancestor: str, person: str) -> bool {
    return (ancestor in ancestors_of(store, person));
}
def parent_of(store: PersonStore, person: str) -> (str | None) {
    if (person not in store._people) {
        return None;
    }
    return store._parent.get(person);
}

