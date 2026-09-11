"""wardle/hades#26 — Terminology graph with cross-system translation edges."""
import from __future__ { annotations }
import from collections { deque }
class TermStore {
    def init(self: TermStore) -> None {
        self._concepts: set[str] = `set();
        self._parents: dict[(str, list[str])] = {};
        self._translations: dict[(str, list[str])] = {};
    }
}
def load_terminology(
    concept_ids: list[str],
    parent_edges: list[tuple[(str, str)]],
    translation_edges: list[tuple[(str, str)]]
) -> TermStore {
    store = TermStore();
    for cid in concept_ids {
        store._concepts.add(cid);
        store._parents.setdefault(cid, []);
        store._translations.setdefault(cid, []);
    }
    for (parent, child) in parent_edges {
        if ((parent in store._concepts) and (child in store._concepts)) {
            store._parents.setdefault(child, []).append(parent);
        }
    }
    for (src, dst) in translation_edges {
        if ((src in store._concepts) and (dst in store._concepts)) {
            store._translations.setdefault(src, []).append(dst);
        }
    }
    return store;
}
def ancestors_of(store: TermStore, concept: str) -> list[str] {
    if (concept not in store._concepts) {
        return [];
    }
    seen: set[str] = `set();
    queue: deque[str] = deque([concept]);
    while queue {
        cur = queue.popleft();
        for par in store._parents.get(cur, []) {
            if (par not in seen) {
                seen.add(par);
                queue.append(par);
            }
        }
    }
    return sorted(seen);
}
def translations_of(store: TermStore, concept: str) -> list[str] {
    if (concept not in store._concepts) {
        return [];
    }
    seen: set[str] = `set();
    queue: deque[str] = deque([concept]);
    while queue {
        cur = queue.popleft();
        for tgt in store._translations.get(cur, []) {
            if (tgt not in seen) {
                seen.add(tgt);
                queue.append(tgt);
            }
        }
    }
    return sorted(seen);
}
def lookup_path(store: TermStore, concept: str, target_system: str) -> list[str] {
    if (concept not in store._concepts) {
        return [];
    }
    for tgt in translations_of(store, concept) {
        if tgt.startswith(target_system) {
            return [concept, tgt];
        }
    }
    return [];
}

