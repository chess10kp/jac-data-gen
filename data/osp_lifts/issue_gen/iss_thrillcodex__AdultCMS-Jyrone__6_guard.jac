"""Guard: thrillcodex/AdultCMS-Jyrone#6."""

node CategoryNode { has slug: str; has removed: bool = False; }
edge ChildOf {}

obj CategoryStore {
    has categories: dict[str, CategoryNode] = {};

    def add_category(slug: str, parent: str | None = None) {
        if parent is not None and self.categories.get(parent, None) is None {
            raise KeyError("unknown parent category");
        }
        n = CategoryNode(slug=slug);
        root ++> n;
        self.categories[slug] = n;
        if parent is not None {
            p = self.categories.get(parent, None);
            if p is not None { p +>:ChildOf:+> n; }
        }
    }

    def cascade_delete(slug: str) -> list[str] {
        start = self.categories.get(slug, None);
        if start is None { raise KeyError("unknown category"); }
        w = start spawn SubtreeCollect(claimed={}, found=[]);
        changed: list[str] = [];
        for sid in w.found {
            n = self.categories.get(sid, None);
            if n is None or n.removed { continue; }
            n.removed = True;
            changed.append(sid);
        }
        return sorted(changed);
    }

    def active_categories() -> list[str] {
        out: list[str] = [];
        for k in self.categories.keys() {
            n = self.categories.get(k, None);
            if n is not None and not n.removed { out.append(k); }
        }
        return sorted(out);
    }
}

walker SubtreeCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with CategoryNode entry {
        if here.slug in self.claimed { skip; }
        self.claimed[here.slug] = True;
        self.found.append(here.slug);
        visit [->:ChildOf:->] else { disengage; };
    }
}

test "category cascade soft delete" {
    s = CategoryStore();
    s.add_category("root");
    s.add_category("videos", parent="root");
    s.add_category("featured", parent="root");
    s.add_category("shorts", parent="videos");
    s.add_category("clips", parent="featured");
    assert s.active_categories() == ["clips", "featured", "root", "shorts", "videos"];
    assert s.cascade_delete("videos") == ["shorts", "videos"];
    assert s.active_categories() == ["clips", "featured", "root"];
}

test "second cascade delete" {
    s = CategoryStore();
    s.add_category("root");
    s.add_category("a", parent="root");
    s.add_category("b", parent="root");
    s.add_category("c", parent="a");
    s.cascade_delete("a");
    assert s.cascade_delete("b") == ["b"];
    assert s.active_categories() == ["root"];
}

test "cycle once only collect" {
    c = CategoryStore();
    c.add_category("a");
    c.add_category("b", parent="a");
    c.categories["a"] +>:ChildOf:+> c.categories["b"];
    c.categories["b"] +>:ChildOf:+> c.categories["a"];
    w = c.categories["a"] spawn SubtreeCollect(claimed={}, found=[]);
    assert sorted(w.found) == ["a", "b"];
}

test "unknown category raises" {
    s = CategoryStore();
    try {
        s.cascade_delete("ghost");
        assert False;
    } except KeyError {
        assert True;
    }
}
