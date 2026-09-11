"""VrUaCom/dmc-rengine-cpp#100 — Nested archive container traversal."""

node Volume {
    has eid: str;
    has kind: str;
}

edge Contains {}

obj ArchiveStore {
    has entries: dict[str, Volume] = {};
}

walker DescendWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Volume entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        self.found.append(here.eid);
        visit [->:Contains:->] else { disengage; };
    }
}

walker AscendWalk {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can step with Volume entry {
        if here.eid in self.claimed { skip; }
        self.claimed[here.eid] = True;
        self.chain.append(here.eid);
        parents = [here <-:Contains:<-][?:Volume];
        if len(parents) == 0 { disengage; }
        pick = parents[0];
        for p in parents {
            if p.eid < pick.eid { pick = p; }
        }
        visit [pick];
    }
}

def load_volumes(
    entries: list[tuple[str, str]],
    contains: list[tuple[str, str]],
) -> ArchiveStore {
    store = ArchiveStore();
    for (eid, kind) in entries {
        nd = Volume(eid=eid, kind=kind);
        root ++> nd;
        store.entries[eid] = nd;
    }
    for (parent, child) in contains {
        p = store.entries.get(parent, None);
        c = store.entries.get(child, None);
        if p is not None and c is not None { p +>:Contains:+> c; }
    }
    return store;
}

def nested_children(store: ArchiveStore, volume_id: str) -> list[str] {
    nd = store.entries.get(volume_id, None);
    if nd is None { return []; }
    found: list[str] = [];
    claimed: dict[str, bool] = {volume_id: True};
    for ch in [nd ->:Contains:->] {
        v: Volume = ch;
        w = v spawn DescendWalk(claimed=claimed, found=found);
        found = w.found;
        claimed = w.claimed;
    }
    return sorted(found);
}

def materialization_path(store: ArchiveStore, entry_id: str) -> list[str] {
    nd = store.entries.get(entry_id, None);
    if nd is None { return []; }
    w = nd spawn AscendWalk(claimed={}, chain=[]);
    return list(reversed(w.chain));
}

def entry_kind(store: ArchiveStore, entry_id: str) -> str | None {
    nd = store.entries.get(entry_id, None);
    if nd is None { return None; }
    return nd.kind;
}
