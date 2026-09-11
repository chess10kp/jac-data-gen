"""beyond-immersion/bannou-service#586 — Internal tag hierarchy for query expansion."""

node Tag {
    has name: str;
}

edge ChildTag {}

obj TagStore {
    has tags: dict[str, Tag] = {};
}

walker DescCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has anchor: str = "";

    can step with Tag entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        if here.name != self.anchor {
            self.found.append(here.name);
        }
        visit [->:ChildTag:->][?:Tag];
    }
}

walker CycleProbe {
    has target: str = "";
    has hit: bool = False;

    can step with Tag entry {
        if here.name == self.target {
            self.hit = True;
            disengage;
        }
        visit [->:ChildTag:->][?:Tag];
    }
}

def load_tags(
    tag_names: list[str],
    parent_edges: list[tuple[str, str]],
) -> TagStore {
    store = TagStore();
    for name in tag_names {
        nd = Tag(name=name);
        root ++> nd;
        store.tags[name] = nd;
    }
    for (parent, child) in parent_edges {
        p = store.tags.get(parent, None);
        c = store.tags.get(child, None);
        if p is not None and c is not None { p +>:ChildTag:+> c; }
    }
    return store;
}

def expand_tags(store: TagStore, tag: str) -> list[str] {
    nd = store.tags.get(tag, None);
    if nd is None { return []; }
    w = nd spawn DescCollect(claimed={}, anchor=tag);
    return sorted(w.found);
}

def would_create_cycle(store: TagStore, parent: str, child: str) -> bool {
    if parent not in store.tags or child not in store.tags { return True; }
    if parent == child { return True; }
    cnd = store.tags[child];
    w = cnd spawn CycleProbe(target=parent);
    return w.hit;
}

def add_tag_relation(store: TagStore, parent: str, child: str) -> bool {
    if would_create_cycle(store, parent, child) { return False; }
    p = store.tags.get(parent, None);
    c = store.tags.get(child, None);
    if p is None or c is None { return False; }
    p +>:ChildTag:+> c;
    return True;
}

test "tag expansion and cycle guard" {
    store = load_tags(
        ["furniture", "chair", "table", "leg"],
        [("furniture", "chair"), ("furniture", "table"), ("table", "leg")],
    );
    assert expand_tags(store, "furniture") == ["chair", "leg", "table"];
    assert would_create_cycle(store, "leg", "furniture") is True;
    assert add_tag_relation(store, "leg", "furniture") is False;
    store2 = load_tags(["a", "b"], []);
    assert add_tag_relation(store2, "a", "b") is True;
    assert expand_tags(store2, "a") == ["b"];
}
