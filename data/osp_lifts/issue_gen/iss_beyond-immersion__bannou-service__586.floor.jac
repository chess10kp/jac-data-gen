"""beyond-immersion/bannou-service#586 — Internal tag hierarchy for query expansion."""
import from __future__ { annotations }
class TagStore {
    def init(self: TagStore) -> None {
        self._tags: set[str] = `set();
        self._parent: dict[(str, (str | None))] = {};
        self._children: dict[(str, list[str])] = {};
    }
}
def load_tags(tag_names: list[str], parent_edges: list[tuple[(str, str)]]) -> TagStore {
    store = TagStore();
    for name in tag_names {
        store._tags.add(name);
        store._parent[name] = None;
        store._children.setdefault(name, []);
    }
    for (parent, child) in parent_edges {
        if ((parent not in store._tags) or (child not in store._tags)) {
            continue;
        }
        store._parent[child] = parent;
        if (child not in store._children[parent]) {
            store._children[parent].append(child);
        }
    }
    return store;
}
def _collect_descendants(store: TagStore, `root: str, acc: set[str]) -> None {
    for ch in store._children.get(`root, []) {
        if (ch in acc) {
            continue;
        }
        acc.add(ch);
        _collect_descendants(store, ch, acc);
    }
}
def expand_tags(store: TagStore, tag: str) -> list[str] {
    if (tag not in store._tags) {
        return [];
    }
    seen: set[str] = `set();
    stack = [tag];
    while stack {
        cur = stack.pop();
        for ch in store._children.get(cur, []) {
            if (ch not in seen) {
                seen.add(ch);
                stack.append(ch);
            }
        }
    }
    extra: set[str] = `set(seen);
    _collect_descendants(store, tag, extra);
    return sorted(extra);
}
def would_create_cycle(store: TagStore, parent: str, child: str) -> bool {
    if ((parent not in store._tags) or (child not in store._tags)) {
        return True;
    }
    if (parent == child) {
        return True;
    }
    frontier = [child];
    visited: set[str] = {child};
    while frontier {
        cur = frontier.pop();
        for nxt in store._children.get(cur, []) {
            if (nxt == parent) {
                return True;
            }
            if (nxt not in visited) {
                visited.add(nxt);
                frontier.append(nxt);
            }
        }
    }
    return False;
}
def add_tag_relation(store: TagStore, parent: str, child: str) -> bool {
    if would_create_cycle(store, parent, child) {
        return False;
    }
    old = store._parent.get(child);
    if ((old is not None) and (child in store._children.get(old, []))) {
        store._children[old].remove(child);
    }
    store._parent[child] = parent;
    if (child not in store._children[parent]) {
        store._children[parent].append(child);
    }
    return True;
}

