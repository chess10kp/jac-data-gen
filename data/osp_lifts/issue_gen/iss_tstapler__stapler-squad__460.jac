"""tstapler/stapler-squad#460 — backlog dependency blocking (OSP lift)."""

obj BacklogStore { has items: dict[str, BacklogItem] = {}; }

node BacklogItem {
    has iid: str;
    has status: str = "idea";
}

edge BlockedBy {}

def load_backlog(
    items: list[str],
    blocked_by: list[tuple[str, str]],
    status: list[tuple[str, str]] | None = None,
) -> BacklogStore {
    b = BacklogStore();
    for iid in items {
        if iid not in b.items {
            it = BacklogItem(iid=iid);
            root ++> it;
            b.items[iid] = it;
        }
    }
    for (item, blocker) in blocked_by {
        x = b.items.get(item, None);
        y = b.items.get(blocker, None);
        if x is not None and y is not None { x +>:BlockedBy:+> y; }
    }
    for (iid, st) in status or [] {
        it: BacklogItem | None = b.items.get(iid, None);
        if it is not None { it.status = st; }
    }
    return b;
}

def _unresolved_blockers(b: BacklogStore, item: BacklogItem) -> list[str] {
    out: list[str] = [];
    for blk in [item ->:BlockedBy:->][?:BacklogItem] {
        if blk.status != "shipped" { out.append(blk.iid); }
    }
    return sorted(out);
}

def is_dequeue_allowed(b: BacklogStore, item: str) -> bool {
    it = b.items.get(item, None);
    if it is None { return False; }
    return len(_unresolved_blockers(b, it)) == 0;
}

def blocked_by_unshipped(b: BacklogStore, item: str) -> list[str] {
    it = b.items.get(item, None);
    if it is None { return []; }
    return _unresolved_blockers(b, it);
}

walker BlockerWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];

    can step with BacklogItem entry {
        if here.iid in self.claimed { skip; }
        self.claimed[here.iid] = True;
        self.hits.append(here.iid);
        for blk in [here ->:BlockedBy:->][?:BacklogItem] {
            if blk.status != "shipped" {
                visit [blk];
            }
        }
    }
}

def transitive_blockers(b: BacklogStore, item: str) -> list[str] {
    it: BacklogItem | None = b.items.get(item, None);
    if it is None { return []; }
    merged: dict[str, bool] = {};
    for blk in [it ->:BlockedBy:->][?:BacklogItem] {
        if blk.status != "shipped" {
            merged[blk.iid] = True;
            w = blk spawn BlockerWalk(claimed={}, hits=[]);
            for h in w.hits { merged[h] = True; }
        }
    }
    return sorted(merged.keys());
}
