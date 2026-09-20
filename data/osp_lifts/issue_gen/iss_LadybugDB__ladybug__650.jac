"""LadybugDB/ladybug#650 — Column segment tree split candidate walk."""

obj SegmentStore {
    has segments: dict[str, Segment] = {};
}

node Segment {
    has sid: str;
    has size: int = 0;
}

edge ChildSegment {}

def load_segments(
    segments: list[str],
    parent_edges: list[tuple[str, str]],
    sizes: list[tuple[str, int]],
) -> SegmentStore {
    store = SegmentStore();
    for sid in segments {
        if sid not in store.segments {
            nd = Segment(sid=sid);
            root ++> nd;
            store.segments[sid] = nd;
        }
    }
    for (parent, child) in parent_edges {
        p = store.segments.get(parent, None);
        c = store.segments.get(child, None);
        if p is not None and c is not None { p +>:ChildSegment:+> c; }
    }
    for (sid, sz) in sizes {
        if sid in store.segments { store.segments[sid].size = sz; }
    }
    return store;
}

def segment_closure(store: SegmentStore, seg_id: str) -> list[str] {
    anchor = store.segments.get(seg_id, None);
    if anchor is None { return []; }
    claimed: dict[str, bool] = {seg_id: True};
    snap: list[str] = [seg_id];
    i = 0;
    while i < len(snap) {
        sid = snap[i];
        i += 1;
        nd = store.segments.get(sid, None);
        if nd is None { continue; }
        for ch in [nd ->:ChildSegment:->][?:Segment] {
            if ch.sid not in claimed {
                claimed[ch.sid] = True;
                snap.append(ch.sid);
            }
        }
    }
    out: list[str] = [];
    for sid in claimed.keys() { out.append(sid); }
    return sorted(out);
}

def oversized_segments(store: SegmentStore, max_size: int) -> list[str] {
    hits: list[str] = [];
    for sid in sorted(store.segments.keys()) {
        if store.segments[sid].size > max_size { hits.append(sid); }
    }
    return hits;
}

def split_candidates(store: SegmentStore, seg_id: str) -> list[str] {
    anchor = store.segments.get(seg_id, None);
    if anchor is None { return []; }
    base = anchor.size;
    hits: list[str] = [];
    for desc in segment_closure(store, seg_id) {
        sz = store.segments[desc].size;
        if sz > base { hits.append(desc); }
    }
    return sorted(hits);
}