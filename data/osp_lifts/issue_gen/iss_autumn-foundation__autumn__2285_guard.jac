"""autumn-foundation/autumn#2285 — Hard delete_comment cascade through reply tree."""

node Comment {
    has cid: str;
    has record_id: str;
}

edge ReplyTo {}

obj CommentStore {
    has comments: dict[str, Comment] = {};
    has counts: dict[str, int] = {};
}

walker SubtreeCollect {
    has record_id: str = "";
    has claimed: dict[str, bool] = {};
    has targets: list[str] = [];

    can step with Comment entry {
        if here.cid in self.claimed { skip; }
        if here.record_id != self.record_id { skip; }
        self.claimed[here.cid] = True;
        self.targets.append(here.cid);
        visit [->:ReplyTo:->][?:Comment];
    }
}

def load_comments(
    records: list[str],
    comments: list[tuple[str, str]],
    replies: list[tuple[str, str]],
    counts: list[tuple[str, int]],
) -> CommentStore {
    store = CommentStore();
    for rid in records { store.counts[rid] = 0; }
    for (cid, rid) in comments {
        if cid not in store.comments {
            nd = Comment(cid=cid, record_id=rid);
            root ++> nd;
            store.comments[cid] = nd;
        }
        store.counts.setdefault(rid, 0);
    }
    for (child, parent) in replies {
        c = store.comments.get(child, None);
        p = store.comments.get(parent, None);
        if c is not None and p is not None { p +>:ReplyTo:+> c; }
    }
    for (rid, count) in counts { store.counts[rid] = count; }
    return store;
}

def delete_comment(store: CommentStore, record_id: str, comment_id: str) -> list[str] {
    nd = store.comments.get(comment_id, None);
    if nd is None { return []; }
    if nd.record_id != record_id { return []; }
    w = nd spawn SubtreeCollect(record_id=record_id, claimed={}, targets=[]);
    removed: list[str] = [];
    for cid in w.targets {
        c = store.comments.get(cid, None);
        if c is not None {
            del store.comments[cid];
            del c;
            removed.append(cid);
        }
    }
    if record_id in store.counts {
        cur = store.counts[record_id];
        new_count = cur - len(removed);
        store.counts[record_id] = new_count if new_count > 0 else 0;
    }
    return sorted(removed);
}

def comment_count(store: CommentStore, record_id: str) -> int {
    return store.counts.get(record_id, 0);
}

def remaining_comments(store: CommentStore, record_id: str) -> list[str] {
    out: list[str] = [];
    for (cid, c) in store.comments.items() {
        if c.record_id == record_id { out.append(cid); }
    }
    return sorted(out);
}

def cross_record_orphans(store: CommentStore, record_id: str) -> list[str] {
    bad: list[str] = [];
    for (cid, c) in store.comments.items() {
        if c.record_id != record_id { continue; }
        parents = [c <-:ReplyTo:<-][?:Comment];
        if len(parents) == 0 { continue; }
        if parents[0].record_id != record_id { bad.append(cid); }
    }
    return bad;
}
test "cascade hard delete" {
    store = load_comments(
        ["recA", "recB"],
        [("c1", "recA"), ("c2", "recA"), ("c3", "recA"), ("c4", "recB")],
        [("c2", "c1"), ("c3", "c2")],
        [("recA", 3), ("recB", 1)],
    );
    removed = delete_comment(store, "recA", "c1");
    assert removed == ["c1", "c2", "c3"];
    assert comment_count(store, "recA") == 0;
    assert remaining_comments(store, "recB") == ["c4"];
}

test "cross record orphan detect" {
    store = load_comments(
        ["recA", "recB"],
        [("root", "recA"), ("orphan", "recB")],
        [("orphan", "root")],
        [("recA", 1), ("recB", 1)],
    );
    assert cross_record_orphans(store, "recB") == ["orphan"];
}
