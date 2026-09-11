"""Guard for rec_22_cms_category_removal -- candidate OSP lift inlined
verbatim (same-prefix sibling imports are unreliable across jac's native
seam), plus behavioral tests: full-closure removal with cross-listed diamond
deleted exactly once, stale/unknown id tolerance, leaf removal keeping
survivors intact, and a no-dangling-reference invariant over survivors.
"""

node Category {
    has cat_id: str;
    has title: str;
    has article_count: int = 0;
}

edge ListedIn {
    has curated: bool = False;   # True for cross-listing ("extra parents")
}

"""Gather the descendant closure below one category."""
walker DescendantScan {
    has doomed: list[Category] = [];
    has seen: dict[str, bool] = {};

    can scan with Category entry {
        if here.cat_id in self.seen {
            skip;           # diamond revisit / cycle policy: collect once,
        }                   # but keep sibling branches alive (no disengage)
        self.seen[here.cat_id] = True;
        self.doomed.append(here);
        visit [->:ListedIn:->];
    }
}

obj CmsCatalog {
    has categories: dict[str, Category];

    """Add a category under an optional parent."""
    def add(cat_id: str, title: str, parent_id: str | None = None) -> Category
    {
        fresh = Category(cat_id=cat_id, title=title);
        if parent_id is not None and parent_id in self.categories {
            parent = self.categories[parent_id];
            parent +>:ListedIn:+> fresh;
        }
        # a parent id absent from the registry is tolerated as inert data
        self.categories[cat_id] = fresh;
        return fresh;
    }

    def cross_list(cat_id: str, extra_parent_id: str)
    {
        extra = self.categories[extra_parent_id];
        item = self.categories[cat_id];
        extra +>:ListedIn(curated=True):+> item;
        return;
    }

    """Remove *cat_id* and every descendant; returns removed ids sorted."""
    def remove_category(cat_id: str) -> list[str]
    {
        start = self.categories.get(cat_id);
        if start is None {
            return [];
        }
        scan = start spawn DescendantScan();
        doomed = scan.doomed;               # includes start itself
        removed = sorted(c.cat_id for c in doomed);
        # Phase APPLY -- mutation strictly after the walk finished.
        for victim in doomed {
            del victim;
        }
        for dead_id in removed {
            _gone = self.categories.pop(dead_id, None);
        }
        return removed;
    }

    """Direct children of a category; stale ids yield an empty list."""
    def children_of(cat_id: str) -> list[str]
    {
        holder = self.categories.get(cat_id);
        if holder is None {
            return [];
        }
        kids = [holder ->:ListedIn:->] as list[Category];
        return sorted(k.cat_id for k in kids);
    }

    def titles() -> list[str]
    {
        return sorted(c.title for c in self.categories.values());
    }
}

"""Build a fresh deterministic catalog; creation order = fixture order."""
def load_graph(spec: list[tuple[str, str, str | None]]) -> CmsCatalog
{
    catalog = CmsCatalog(categories={});
    for row in spec {
        _made = catalog.add(row[0], row[1], row[2]);
    }
    return catalog;
}

test "full_closure_diamond_deleted_once" {
    catalog = load_graph(spec=[
        ("news", "News", None),
        ("world", "World", "news"),
        ("politics", "Politics", "news"),
        ("sports", "Sports", None),
        ("tennis", "Tennis", "sports"),
        ("reactions", "Reactions", "world")
    ]);
    catalog.cross_list("reactions", "tennis");
    removed = catalog.remove_category("news");
    assert removed == ["news", "politics", "reactions", "world"];
    assert catalog.categories.get("reactions") is None;
    assert sorted(catalog.categories.keys()) == ["sports", "tennis"];
    assert catalog.titles() == ["Sports", "Tennis"];
    # invariant: every survivor's children resolve to live categories only
    for cid in catalog.categories.keys() {
        for kid in catalog.children_of(cid) {
            assert kid in catalog.categories;
        }
    }
}

test "unknown_and_stale_refs_tolerated" {
    catalog = load_graph(spec=[
        ("news", "News", None),
        ("tennis", "Tennis", "deleted-long-ago")
    ]);
    assert catalog.remove_category("ghost") == [];
    assert catalog.children_of("deleted-long-ago") == [];
    assert catalog.children_of("ghost") == [];
    assert catalog.categories.get("tennis") is not None;
}

test "leaf_removal_keeps_rest_intact" {
    catalog = load_graph(spec=[
        ("news", "News", None),
        ("politics", "Politics", "news"),
        ("world", "World", "news")
    ]);
    assert catalog.remove_category("politics") == ["politics"];
    assert catalog.children_of("news") == ["world"];
    # invariant: no survivor references a removed id
    for cid in catalog.categories.keys() {
        assert "politics" not in catalog.children_of(cid);
    }
}


test "adversarial_diamond_revisit_queued_before_deep" {
    # Shape: R -> [c1, Q]; c1 -> S -> deep; Q -> S (diamond closing edge).
    # Frontier run: c1 queues S, Q queues S again -- the second arrival of S
    # sits in the queue AHEAD of deep. A disengage-on-revisit would abort
    # the sweep there and silently drop deep from the closure; skip must
    # keep collecting.
    catalog = load_graph(spec=[
        ("R", "R", None),
        ("c1", "COne", "R"),
        ("Q", "Q", "R"),
        ("S", "S", "c1"),
        ("deep", "Deep", "S")
    ]);
    catalog.cross_list("S", "Q");
    removed = catalog.remove_category("R");
    assert sorted(removed) == ["Q", "R", "S", "c1", "deep"];
    assert catalog.categories.get("deep") is None;
    assert len(catalog.categories.keys()) == 0;
}
