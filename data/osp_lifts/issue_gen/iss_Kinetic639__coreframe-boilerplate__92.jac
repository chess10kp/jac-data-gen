"""Kinetic639/coreframe-boilerplate#92 — Category tree descent and level refresh."""

obj CategoryStore {
    has categories: dict[str, Category] = {};
}

node Category {
    has cid: str;
    has level: int = 0;
}

edge ParentOf {}

def load_categories(
    categories: list[str],
    parent_edges: list[tuple[str, str]],
    levels: list[tuple[str, int]],
) -> CategoryStore {
    store = CategoryStore();
    for cid in categories {
        if cid not in store.categories {
            nd = Category(cid=cid);
            root ++> nd;
            store.categories[cid] = nd;
        }
    }
    for (parent, child) in parent_edges {
        p = store.categories.get(parent, None);
        c = store.categories.get(child, None);
        if p is not None and c is not None { p +>:ParentOf:+> c; }
    }
    for (cid, lvl) in levels {
        if cid in store.categories { store.categories[cid].level = lvl; }
    }
    return store;
}

def get_ancestors(store: CategoryStore, cat_id: str) -> list[str] {
    anchor = store.categories.get(cat_id, None);
    if anchor is None { return []; }
    chain: list[str] = [];
    cur: Category | None = anchor;
    seen: dict[str, bool] = {};
    while cur is not None {
        if cur.cid in seen { break; }
        seen[cur.cid] = True;
        chain.append(cur.cid);
        parents = [cur <-:ParentOf:<-][?:Category];
        if not parents { break; }
        cur = parents[0];
    }
    if len(chain) > 0 { chain = chain[1:]; }
    return chain;
}

def is_descendant(store: CategoryStore, target_id: str, category_id: str) -> bool {
    if target_id not in store.categories or category_id not in store.categories {
        return False;
    }
    ancestors = get_ancestors(store, target_id);
    for a in ancestors {
        if a == category_id { return True; }
    }
    return False;
}

def update_children_levels(
    store: CategoryStore,
    parent_id: str,
    parent_level: int,
) -> list[str] {
    anchor = store.categories.get(parent_id, None);
    if anchor is None { return []; }
    updated: list[str] = [];
    snap: list[tuple[str, int]] = [(parent_id, parent_level)];
    i = 0;
    while i < len(snap) {
        (cid, lvl) = snap[i];
        i += 1;
        nd = store.categories.get(cid, None);
        if nd is None { continue; }
        for ch in [nd ->:ParentOf:->][?:Category] {
            new_lvl = lvl + 1;
            if ch.level != new_lvl {
                ch.level = new_lvl;
                updated.append(ch.cid);
            }
            snap.append((ch.cid, new_lvl));
        }
    }
    return sorted(updated);
}