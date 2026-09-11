"""Idiomatic OSP lift: CMS category cascade removal (category C5).

Two-phase mutation protocol (OSP_IDIOMIZE_TASK.md §5.5):

Phase COLLECT -- `DescendantScan` gathers the doomed id closure into typed
`has` fields. The seen-guard on category ids is the once-only guard for
cross-listed diamonds AND the explicit cycle policy (no built-in dedup in
0.36.1): a revisited id disengages that path. Unknown ids are skipped, so a
stale parent reference is tolerated exactly as in the source.

Phase APPLY -- outside any walk, each doomed node is disconnected from its
`ListedIn` edges and destroyed once, then dropped from the registry dict.
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
