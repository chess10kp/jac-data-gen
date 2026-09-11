"""jflournoy/story-time#41 — outline beat tree CRUD with recursive descendant deletion."""

glob STATUS_OUTLINE = "outline";
glob REL_REQUIRES = "requires";

node OutlineBeat {
    has beat_id: str;
    has session_id: str;
    has position: int;
    has depth: int;
    has content: str;
    has status: str;
    has deleted: bool = False;
}

node WorldRef {
    has fact_id: str;
    has relationship: str;
}

edge ChildOf {}
edge HasWorldRef {}

obj OutlineStore {
    has beats: dict[str, OutlineBeat] = {};
}

walker TreeWalk {
    has claimed: dict[str, bool] = {};
    has ids: list[str] = [];

    can step with OutlineBeat entry {
        if here.beat_id in self.claimed { skip; }
        self.claimed[here.beat_id] = True;
        self.ids.append(here.beat_id);
        kids = _sorted_children(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_children(nd: OutlineBeat) -> list[OutlineBeat] {
    kids: list[OutlineBeat] = [nd ->:ChildOf:->][?:OutlineBeat];
    names: list[str] = [];
    for ch in kids { names.append(ch.beat_id); }
    names = sorted(names);
    out: list[OutlineBeat] = [];
    for nm in names { for ch in kids { if ch.beat_id == nm { out.append(ch); } } }
    return out;
}

def fresh_outline_store() -> OutlineStore {
    return OutlineStore();
}

def register_beat(
    beat_id: str,
    session_id: str,
    position: int,
    depth: int,
    content: str,
    status: str,
    store: OutlineStore | None = None,
    parent_id: str | None = None,
) -> OutlineStore {
    s = store;
    if s is None { s = fresh_outline_store(); }
    if beat_id in s.beats { raise ValueError("duplicate beat id"); }
    nd = OutlineBeat(beat_id=beat_id, session_id=session_id, position=position, depth=depth, content=content, status=status);
    root ++> nd;
    s.beats[beat_id] = nd;
    if parent_id is not None { link_child(parent_id, beat_id, s); }
    return s;
}

def link_child(parent_id: str, child_id: str, store: OutlineStore) {
    if parent_id not in store.beats or child_id not in store.beats { raise KeyError("unknown beat id"); }
    if parent_id == child_id { return; }
    ch_nd = store.beats[child_id];
    for p in [ch_nd <-:ChildOf:<-][?:OutlineBeat] { raise ValueError("child already has parent"); }
    par_nd = store.beats[parent_id];
    seen = False;
    for ex in [par_nd ->:ChildOf:->][?:OutlineBeat] { if ex.beat_id == child_id { seen = True; } }
    if not seen { par_nd +>:ChildOf:+> ch_nd; }
}

def get_descendant_ids(beat_id: str, store: OutlineStore) -> list[str] {
    if beat_id not in store.beats { raise KeyError(beat_id); }
    w = store.beats[beat_id] spawn TreeWalk(claimed={}, ids=[]);
    reach: list[str] = [];
    for bid in w.ids {
        if bid != beat_id and not store.beats[bid].deleted { reach.append(bid); }
    }
    return sorted(reach);
}

def list_session_beats(session_id: str, store: OutlineStore) -> list[str] {
    rows: list[tuple[int, int, str]] = [];
    for bid in store.beats {
        nd = store.beats[bid];
        if nd.session_id == session_id and not nd.deleted { rows.append((nd.depth, nd.position, bid)); }
    }
    rows = sorted(rows);
    out: list[str] = [];
    for (d, p, bid) in rows { out.append(bid); }
    return out;
}

def delete_beat_cascade(beat_id: str, store: OutlineStore) -> list[str] {
    if beat_id not in store.beats { raise KeyError(beat_id); }
    start = store.beats[beat_id];
    if start.deleted { return []; }
    w = start spawn TreeWalk(claimed={}, ids=[]);
    deleted: list[str] = [];
    for bid in w.ids {
        nd = store.beats.get(bid, None);
        if nd is not None and not nd.deleted {
            nd.deleted = True;
            deleted.append(bid);
        }
    }
    return sorted(deleted);
}

def add_world_ref(beat_id: str, fact_id: str, relationship: str, store: OutlineStore) {
    if beat_id not in store.beats { raise KeyError("unknown beat id"); }
    ref = WorldRef(fact_id=fact_id, relationship=relationship);
    root ++> ref;
    store.beats[beat_id] +>:HasWorldRef:+> ref;
}

def world_refs_for_beat(beat_id: str, store: OutlineStore) -> list[tuple[str, str]] {
    if beat_id not in store.beats { raise KeyError(beat_id); }
    out: list[tuple[str, str]] = [];
    for ref in [store.beats[beat_id] ->:HasWorldRef:->][?:WorldRef] {
        out.append((ref.fact_id, ref.relationship));
    }
    return sorted(out);
}
