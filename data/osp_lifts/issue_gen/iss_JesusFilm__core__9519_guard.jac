"""JesusFilm/core#9519 -- parent-variant shared recompute."""

node Video {
    has vid: str;
    has label: str;
    has langs: list[str] = [];
}

edge Parent {}

obj VideoStore {
    has vids: dict[str, Video] = {};
}

walker LangClosure {
    has claimed: dict[str, bool] = {};
    has langs: set[str] = set();
    can step with Video entry {
        if here.vid in self.claimed { skip; }
        self.claimed[here.vid] = True;
        for l in here.langs { self.langs.add(l); }
        visit [->:Parent:->][?:Video];
    }
}

def make_store() -> VideoStore {
    return VideoStore();
}

def add_video(store: VideoStore, vid: str, parent: str | None, label: str, langs: set[str]) -> None {
    if vid in store.vids { raise ValueError("duplicate video"); }
    v = Video(vid=vid, label=label, langs=sorted(list(langs)));
    root ++> v;
    store.vids[vid] = v;
    if parent is not None {
        if not (parent in store.vids) {
            pv = Video(vid=parent, label="container", langs=[]);
            root ++> pv;
            store.vids[parent] = pv;
        }
        store.vids[parent] +>:Parent:+> v;
    }
}

def _shared_parent_lookup(store: VideoStore, vid: str) -> str | None {
    if not (vid in store.vids) { return None; }
    # find parent via reverse edge with container label restriction
    for k in store.vids {
        for ch in [store.vids[k] ->:Parent:->][?:Video] {
            if ch.vid == vid {
                if store.vids[k].label == "container" { return k; }
            }
        }
    }
    return None;
}

def recompute_available(store: VideoStore, vid: str) -> set[str] {
    if not (vid in store.vids) { return set(); }
    w = store.vids[vid] spawn LangClosure(claimed={}, langs=set());
    return w.langs;
}

def create_empty_parent_variant(store: VideoStore, parent_id: str) -> str {
    if not (parent_id in store.vids) { raise KeyError(parent_id); }
    if store.vids[parent_id].label != "container" { raise ValueError("not a container parent"); }
    variant_id = parent_id + "::variant";
    if variant_id in store.vids { return variant_id; }
    add_video(store, variant_id, parent_id, "variant", set());
    # recompute via shared engine (write through)
    langs = recompute_available(store, parent_id);
    store.vids[parent_id].langs = sorted(list(langs));
    return variant_id;
}

def check_and_remove_empty_parent_variant(store: VideoStore, variant_id: str) -> bool {
    if not (variant_id in store.vids) { return False; }
    parent = _shared_parent_lookup(store, variant_id);
    if parent is None { return False; }
    if store.vids[variant_id].langs.__len__() > 0 { return False; }
    # remove: disconnect then del
    pnode = store.vids[parent];
    vnode = store.vids[variant_id];
    pnode del ->:Parent:-> vnode;
    del vnode;
    store.vids.__delitem__(variant_id);
    langs = recompute_available(store, parent);
    store.vids[parent].langs = sorted(list(langs));
    return True;
}

def available_languages(store: VideoStore, vid: str) -> list[str] {
    if not (vid in store.vids) { return []; }
    return sorted(store.vids[vid].langs);
}
test "recompute union" {
    store = make_store();
    add_video(store, "parent", None, "container", {"en"});
    add_video(store, "child1", "parent", "variant", {"es"});
    add_video(store, "child2", "parent", "variant", {"fr"});
    assert recompute_available(store, "parent") == {"en", "es", "fr"};
}

test "create empty variant recomputes" {
    store = make_store();
    add_video(store, "p", None, "container", {"en"});
    vid = create_empty_parent_variant(store, "p");
    assert vid == "p::variant";
    assert available_languages(store, "p") == ["en"];
}

test "cleanup removes empty only" {
    store = make_store();
    add_video(store, "p", None, "container", {"en"});
    create_empty_parent_variant(store, "p");
    assert check_and_remove_empty_parent_variant(store, "p::variant") == True;
    assert not ("p::variant" in store.vids);
    add_video(store, "p2", None, "container", {"en"});
    add_video(store, "v", "p2", "variant", {"de"});
    assert check_and_remove_empty_parent_variant(store, "v") == False;
}

test "shared lookup restricts to container" {
    store = make_store();
    add_video(store, "leaf", None, "leaf", {"en"});
    empty_langs: set[str] = set();
    add_video(store, "c", "leaf", "variant", empty_langs);
    assert _shared_parent_lookup(store, "c") == None;
    assert check_and_remove_empty_parent_variant(store, "c") == False;
}

test "diamond closure" {
    store = make_store();
    empty_langs: set[str] = set();
    add_video(store, "root", None, "container", empty_langs);
    add_video(store, "a", "root", "variant", {"en"});
    add_video(store, "b", "root", "variant", {"es"});
    assert recompute_available(store, "root") == {"en", "es"};
}