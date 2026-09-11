"""FraOri03/Lattice#202 — render cache invalidation downstream sweep."""

node Clip {
    has cid: str;
    has dirty: bool = False;
}

edge Invalidates {}

obj TimelineStore {
    has clips: dict[str, Clip] = {};
}

walker InvalidateWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with Clip entry {
        if here.cid not in self.claimed {
            self.claimed[here.cid] = True;
            self.found.append(here.cid);
        }
        visit [->:Invalidates:->][?:Clip];
    }
}

def load_timeline(
    clips: list[str],
    invalidates_edges: list[tuple[str, str]],
) -> TimelineStore {
    store = TimelineStore();
    for cid in clips {
        nd = Clip(cid=cid);
        root ++> nd;
        store.clips[cid] = nd;
    }
    for (src, dst) in invalidates_edges {
        s = store.clips.get(src, None);
        d = store.clips.get(dst, None);
        if s is not None and d is not None { s +>:Invalidates:+> d; }
    }
    return store;
}

def invalidated_clips(store: TimelineStore, changed: list[str]) -> list[str] {
    acc: dict[str, bool] = {};
    for ch in changed {
        nd = store.clips.get(ch, None);
        if nd is None { continue; }
        w = nd spawn InvalidateWalk(claimed={ch: True});
        for cid in w.found { acc[cid] = True; }
    }
    return sorted(acc.keys());
}

def invalidate_cache(store: TimelineStore, clip_id: str) -> list[str] {
    if clip_id not in store.clips { return []; }
    swept = sorted([clip_id] + invalidated_clips(store, [clip_id]));
    for cid in swept {
        nd = store.clips.get(cid, None);
        if nd is not None { nd.dirty = True; }
    }
    return swept;
}

def is_dirty(store: TimelineStore, clip_id: str) -> bool {
    nd = store.clips.get(clip_id, None);
    if nd is None { return False; }
    return nd.dirty;
}

test "downstream invalidation chain" {
    tl = load_timeline(
        ["src", "fx", "comp", "out"],
        [("src", "fx"), ("fx", "comp"), ("comp", "out")],
    );
    assert invalidated_clips(tl, ["src"]) == ["comp", "fx", "out"];
    assert invalidate_cache(tl, "src") == ["comp", "fx", "out", "src"];
}

test "diamond invalidation revisit" {
    tl = load_timeline(
        ["edit", "a", "b", "mix"],
        [("edit", "a"), ("edit", "b"), ("a", "mix"), ("b", "mix")],
    );
    assert invalidated_clips(tl, ["edit"]) == ["a", "b", "mix"];
}
