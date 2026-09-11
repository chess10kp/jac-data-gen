"""spring-projects/spring-security#19513 — ACL parent ancestry and cycle guard."""
import from __future__ { annotations }
class AclStore {
    def init(self: AclStore) -> None {
        self._acls: set[str] = `set();
        self._parent: dict[(str, (str | None))] = {};
    }
}
def load_acls(acls: list[str], parent_edges: list[tuple[(str, str)]]) -> AclStore {
    store = AclStore();
    for aid in acls {
        store._acls.add(aid);
        store._parent[aid] = None;
    }
    for (child, parent) in parent_edges {
        if ((child in store._acls) and (parent in store._acls)) {
            store._parent[child] = parent;
        }
    }
    return store;
}
def _ancestor_chain(store: AclStore, acl_id: str) -> list[str] {
    chain: list[str] = [acl_id];
    seen: set[str] = {acl_id};
    cur = acl_id;
    while True {
        parent = store._parent.get(cur);
        if (parent is None) {
            break;
        }
        if (parent in seen) {
            raise ValueError(f"parent cycle detected at {parent}");
        }
        seen.add(parent);
        chain.append(parent);
        cur = parent;
    }
    return chain;
}
def ancestor_ids(store: AclStore, acl_id: str) -> list[str] {
    if (acl_id not in store._acls) {
        return [];
    }
    chain = _ancestor_chain(store, acl_id);
    return sorted(chain[1:]);
}
def would_create_cycle(store: AclStore, child_id: str, new_parent_id: str) -> bool {
    if ((child_id not in store._acls) or (new_parent_id not in store._acls)) {
        return False;
    }
    if (child_id == new_parent_id) {
        return True;
    }
    try {
        for anc in _ancestor_chain(store, new_parent_id) {
            if (anc == child_id) {
                return True;
            }
        }
    } except ValueError {
        return True;
    }
    return False;
}
def set_parent(store: AclStore, child_id: str, parent_id: (str | None)) -> None {
    if (child_id not in store._acls) {
        raise KeyError(child_id);
    }
    if ((parent_id is not None) and (parent_id not in store._acls)) {
        raise KeyError(parent_id);
    }
    if ((parent_id is not None) and would_create_cycle(store, child_id, parent_id)) {
        raise ValueError("parent assignment would create cycle");
    }
    store._parent[child_id] = parent_id;
}
def lookup_ancestors_safe(store: AclStore, acl_id: str) -> list[str] {
    if (acl_id not in store._acls) {
        return [];
    }
    chain: list[str] = [];
    seen: set[str] = `set();
    cur: (str | None) = acl_id;
    while (cur is not None) {
        if (cur in seen) {
            raise ValueError(f"stored parent cycle at {cur}");
        }
        seen.add(cur);
        parent = store._parent.get(cur);
        if (parent is None) {
            break;
        }
        chain.append(parent);
        cur = parent;
    }
    return sorted(chain);
}

