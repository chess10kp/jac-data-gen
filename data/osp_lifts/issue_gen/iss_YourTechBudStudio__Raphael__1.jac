"""Raphael durable text-note hierarchy — YourTechBudStudio/Raphael#1."""

node RaphaelRoot {
    has favorites: dict[str, bool] = {};
}

node NoteNode {
    has cid: str;
    has kind: str;
    has title: str;
    has archived: bool = False;
}

edge Contains {}

walker FindWalker {
    has target: str;
    has claimed: dict[str, bool] = {};
    has found: NoteNode | None = None;

    can seek_root with RaphaelRoot entry {
        kids: list[NoteNode] = [];
        for ch in [here ->:Contains:->][?:NoteNode] {
            kids.append(ch);
        }
        if len(kids) == 0 {
            disengage;
        } else {
            for i in range(len(kids) - 1, -1, -1) {
                visit :0: [kids[i]];
            }
        }
        print ["find", self.target];
    }

    can seek_note with NoteNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid == self.target {
            self.found = here;
            print ["found", here.cid];
            disengage;
        }
        kids: list[NoteNode] = [];
        for ch in [here ->:Contains:->][?:NoteNode] {
            kids.append(ch);
        }
        if len(kids) == 0 {
            disengage;
        } else {
            for i in range(len(kids) - 1, -1, -1) {
                visit :0: [kids[i]];
            }
        }
    }
}

walker DescendWalker {
    has start_id: str;
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with NoteNode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid != self.start_id {
            self.found.append(here.cid);
        }
        kids: list[NoteNode] = [];
        for ch in [here ->:Contains:->][?:NoteNode] {
            kids.append(ch);
        }
        if len(kids) == 0 {
            disengage;
        } else {
            for i in range(len(kids) - 1, -1, -1) {
                visit :0: [kids[i]];
            }
        }
        print ["descend", len(self.found)];
    }
}

def make_store() -> RaphaelRoot {
    store = RaphaelRoot();
    root ++> store;
    return store;
}

def create_child(store: RaphaelRoot, parent_id: str, kind: str, title: str, cid: str) -> dict | None {
    parent = _resolve_node(store, parent_id);
    if parent is None { return None; }
    nd = NoteNode(cid=cid, kind=kind, title=title);
    parent +>:Contains:+> nd;
    return _node_dict(nd, cid in store.favorites);
}

def get_node(store: RaphaelRoot, node_id: str) -> dict | None {
    nd = _resolve_node(store, node_id);
    if nd is None { return None; }
    return _node_dict(nd, node_id in store.favorites);
}

def list_children(store: RaphaelRoot, parent_id: str, recursive: bool = False) -> list[str] {
    parent = _resolve_node(store, parent_id);
    if parent is None { return []; }
    if not recursive {
        ids: list[str] = [];
        for ch in [parent ->:Contains:->][?:NoteNode] {
            ids.append(ch.cid);
        }
        return sorted(ids);
    }
    w = parent spawn DescendWalker(start_id=parent.cid, claimed={});
    return sorted(w.found);
}

def add_favorite(store: RaphaelRoot, node_id: str) -> bool {
    if _resolve_node(store, node_id) is None { return False; }
    store.favorites[node_id] = True;
    return True;
}

def remove_favorite(store: RaphaelRoot, node_id: str) -> bool {
    if node_id in store.favorites {
        del store.favorites[node_id];
    }
    return True;
}

def set_archived(store: RaphaelRoot, node_id: str, archived: bool) -> bool {
    nd = _resolve_node(store, node_id);
    if nd is None { return False; }
    nd.archived = archived;
    return True;
}

def list_favorites(store: RaphaelRoot) -> list[dict] {
    rows: list[dict] = [];
    for node_id in store.favorites {
        nd = _resolve_node(store, node_id);
        if nd is None { continue; }
        if nd.archived { continue; }
        rows.append(_node_dict(nd, True));
    }
    return _sort_favorite_rows(rows);
}

def _resolve_node(store: RaphaelRoot, node_id: str) -> NoteNode | None {
    w = store spawn FindWalker(target=node_id, claimed={});
    return w.found;
}

def _node_dict(nd: NoteNode, is_favorite: bool) -> dict {
    return {"cid": nd.cid, "kind": nd.kind, "title": nd.title, "isFavorite": is_favorite};
}

def _sort_favorite_rows(rows: list[dict]) -> list[dict] {
    out: list[dict] = rows;
    n = len(out);
    for i in range(n) {
        for j in range(0, n - i - 1) {
            a = out[j] as dict;
            b = out[j + 1] as dict;
            swap = False;
            if (a["title"] as str) > (b["title"] as str) { swap = True; }
            elif (a["title"] as str) == (b["title"] as str) and (a["cid"] as str) > (b["cid"] as str) {
                swap = True;
            }
            if swap {
                tmp = out[j];
                out[j] = out[j + 1];
                out[j + 1] = tmp;
            }
        }
    }
    return out;
}
