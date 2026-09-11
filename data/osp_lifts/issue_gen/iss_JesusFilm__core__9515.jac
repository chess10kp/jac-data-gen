"""JesusFilm/core#9515 — Video availableLanguages upward recompute with cascade."""

node VideoNode {
    has vid: str;
    has parent_id: str | None = None;
    has own_langs: list[str] = [];
    has available: list[str] = [];
}

edge ChildOf {}

obj VideoStore {
    has videos: dict[str, VideoNode] = {};
}

walker LangCollect {
    has claimed: dict[str, bool] = {};
    has langs: list[str] = [];
    has cycle: bool = False;

    can step with VideoNode entry {
        if here.vid in self.claimed {
            self.cycle = True;
            skip;
        }
        self.claimed[here.vid] = True;
        for lg in here.own_langs {
            if lg not in self.langs { self.langs.append(lg); }
        }
        visit [->:ChildOf:->][?:VideoNode];
    }
}

def load_video_store(
    videos: list[str],
    parent_map: dict[str, str | None],
    own_langs: dict[str, list[str]],
) -> VideoStore {
    s = VideoStore();
    for vid in videos {
        langs = own_langs.get(vid, []);
        nd = VideoNode(vid=vid, own_langs=sorted(langs), parent_id=parent_map.get(vid, None));
        root ++> nd;
        s.videos[vid] = nd;
    }
    for (vid, parent) in parent_map.items() {
        if parent is None { continue; }
        p = s.videos.get(parent, None);
        c = s.videos.get(vid, None);
        if p is not None and c is not None { p +>:ChildOf:+> c; }
    }
    for vid in videos {
        s.videos[vid].available = _compute_available(s, vid);
    }
    return s;
}

def _compute_available(store: VideoStore, video_id: str) -> list[str] {
    nd = store.videos.get(video_id, None);
    if nd is None { return []; }
    w = nd spawn LangCollect(claimed={}, langs=[], cycle=False);
    if w.cycle { raise ValueError("cycle detected"); }
    out = list(w.langs);
    return sorted(out);
}

def recompute_upward(store: VideoStore, start_id: str) -> list[str] {
    if store.videos.get(start_id, None) is None { return []; }
    changed: list[str] = [];
    cur_id: str | None = start_id;
    while cur_id is not None {
        nd = store.videos.get(cur_id, None);
        if nd is None { break; }
        new_val = _compute_available(store, cur_id);
        if nd.available != new_val {
            nd.available = new_val;
            changed.append(cur_id);
        }
        parent_id: str | None = nd.parent_id;
        cur_id = parent_id;
    }
    return sorted(changed);
}

def remove_child(store: VideoStore, parent_id: str, child_id: str) -> list[str] {
    p = store.videos.get(parent_id, None);
    c = store.videos.get(child_id, None);
    if p is not None and c is not None {
        p del ->:ChildOf:-> c;
        c.parent_id = None;
    }
    return recompute_upward(store, parent_id);
}

def get_available(store: VideoStore, video_id: str) -> list[str] {
    nd = store.videos.get(video_id, None);
    if nd is None { return []; }
    return list(nd.available);
}
