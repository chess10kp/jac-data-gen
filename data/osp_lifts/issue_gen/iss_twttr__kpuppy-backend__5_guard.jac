"""twttr/kpuppy-backend#5 — single-pass comment tree load (CTE lift)."""

node Store {
    has sid: str = "store";
}

node Comment {
    has cid: str;
    has content_id: str;
    has parent_id: str = "";
    has body: str = "";
    has created_at: str = "";
}

edge Reply {}
edge TopLevel {}

def row_parent_id(row: dict[str, object]) -> str {
    pid: str = "";
    if "parent_id" in row {
        if row["parent_id"] is not None {
            pid = str(row["parent_id"]);
        }
    }
    return pid;
}

def sort_records(items: list[dict[str, object]]) -> list[dict[str, object]] {
    keys: list[str] = [];
    for it in items {
        keys.append(str(it["created_at"]) + "|" + str(it["id"]));
    }
    keys = sorted(keys);
    out: list[dict[str, object]] = [];
    for k in keys {
        for it in items {
            if (str(it["created_at"]) + "|" + str(it["id"])) == k {
                out.append(it);
            }
        }
    }
    return out;
}

def reply_children(here: Comment) -> list[Comment] {
    raw: list[Comment] = [];
    for nd in [here ->:Reply:->] {
        ch = nd as Comment;
        raw.append(ch);
    }
    keys: list[str] = [];
    for ch in raw {
        keys.append(ch.created_at + "|" + ch.cid);
    }
    keys = sorted(keys);
    out: list[Comment] = [];
    for k in keys {
        for ch in raw {
            if (ch.created_at + "|" + ch.cid) == k {
                out.append(ch);
            }
        }
    }
    return out;
}

def top_level_comments(st: Store) -> list[Comment] {
    raw: list[Comment] = [];
    for nd in [st ->:TopLevel:->] {
        ch = nd as Comment;
        raw.append(ch);
    }
    keys: list[str] = [];
    for ch in raw {
        keys.append(ch.created_at + "|" + ch.cid);
    }
    keys = sorted(keys);
    out: list[Comment] = [];
    for k in keys {
        for ch in raw {
            if (ch.created_at + "|" + ch.cid) == k {
                out.append(ch);
            }
        }
    }
    return out;
}

def build_comment_store(rows: list[dict[str, object]]) -> Store {
    st = Store();
    root ++> st;
    by_id: dict[str, Comment] = {};
    for row in rows {
        nd = Comment(
            cid=str(row["id"]),
            content_id=str(row["content_id"]),
            parent_id=row_parent_id(row),
            body=str(row.get("body", "")),
            created_at=str(row.get("created_at", ""))
        );
        root ++> nd;
        by_id[nd.cid] = nd;
    }
    for row in rows {
        cid = str(row["id"]);
        pid = row_parent_id(row);
        nd = by_id[cid];
        if pid == "" {
            st +>:TopLevel:+> nd;
        } elif pid in by_id {
            by_id[pid] +>:Reply:+> nd;
        }
    }
    return st;
}

walker FindById {
    has target: str = "";
    has result: Comment | None = None;
    has claimed: dict[str, bool] = {};

    can walk_store with Store entry {
        tops: list[Comment] = top_level_comments(here);
        for ch in tops {
            visit [ch];
        }
        print self.target;
    }

    can walk_comment with Comment entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.cid == self.target {
            self.result = here;
            disengage;
        }
        kids: list[Comment] = reply_children(here);
        for ch in kids {
            visit [ch];
        }
        print here.cid;
    }
}

walker ContentTree {
    has claimed: dict[str, bool] = {};
    has max_depth: int = 10;
    has content_id: str = "";
    has depths: dict[str, int] = {};
    has found: list[dict[str, object]] = [];

    can walk_store with Store entry {
        tops: list[Comment] = top_level_comments(here);
        for ch in tops {
            if ch.content_id == self.content_id {
                visit :0: [ch];
            }
        }
        print self.content_id;
    }

    can walk_comment with Comment entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.content_id != self.content_id {
            disengage;
        }
        d: int = 0;
        if here.parent_id != "" {
            if here.parent_id in self.depths {
                d = self.depths[here.parent_id] + 1;
            } else {
                d = 1;
            }
        }
        if d >= self.max_depth {
            disengage;
        }
        self.depths[here.cid] = d;
        item: dict[str, object] = {};
        item["id"] = here.cid;
        item["content_id"] = here.content_id;
        item["parent_id"] = here.parent_id;
        item["body"] = here.body;
        item["created_at"] = here.created_at;
        item["depth"] = d;
        self.found.append(item);
        kids: list[Comment] = reply_children(here);
        for ch in kids {
            visit :0: [ch];
        }
        print here.cid;
    }
}

walker SubtreeCollect {
    has root_parent: str = "";
    has max_depth: int = 10;
    has claimed: dict[str, bool] = {};
    has depths: dict[str, int] = {};
    has found: list[dict[str, object]] = [];

    can enter_root with Comment entry {
        if here.cid != self.root_parent {
            disengage;
        }
        kids: list[Comment] = reply_children(here);
        for ch in kids {
            visit :0: [ch];
        }
        print self.root_parent;
        disengage;
    }

    can step_child with Comment entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        d: int = 0;
        if here.parent_id != self.root_parent {
            if here.parent_id in self.depths {
                d = self.depths[here.parent_id] + 1;
            } else {
                d = 1;
            }
        }
        if d >= self.max_depth {
            disengage;
        }
        self.depths[here.cid] = d;
        item: dict[str, object] = {};
        item["id"] = here.cid;
        item["content_id"] = here.content_id;
        item["parent_id"] = here.parent_id;
        item["body"] = here.body;
        item["created_at"] = here.created_at;
        item["depth"] = d;
        self.found.append(item);
        kids: list[Comment] = reply_children(here);
        for ch in kids {
            visit :0: [ch];
        }
        print here.cid;
    }
}

def get_replies(store: Store, parent_id: str, max_depth: int = 10) -> list[dict[str, object]] {
    if parent_id == "" {
        return [];
    }
    fw = store spawn FindById(target=parent_id);
    if fw.result is None {
        return [];
    }
    sw = fw.result spawn SubtreeCollect(root_parent=parent_id, max_depth=max_depth);
    return sort_records(sw.found);
}

def get_by_content_id(store: Store, content_id: str, max_depth: int = 10) -> list[dict[str, object]] {
    w = store spawn ContentTree(content_id=content_id, max_depth=max_depth);
    return sort_records(w.found);
}

walker GuardTouch {
    can ping with root entry {
        print "guard";
    }
}

test "get_replies_empty_parent" {
    with entry {
        root spawn GuardTouch;
        rows: list[dict[str, object]] = [];
        st = build_comment_store(rows);
        r = get_replies(st, "", 10);
        assert len(r) == 0;;
    }
}

test "get_replies_unknown_parent" {
    with entry {
        root spawn GuardTouch;
        row: dict[str, object] = {};
        row["id"] = "1";
        row["content_id"] = "c1";
        row["parent_id"] = None;
        row["body"] = "a";
        row["created_at"] = "2020-01-01";
        rows: list[dict[str, object]] = [row];
        st = build_comment_store(rows);
        r = get_replies(st, "missing", 10);
        assert len(r) == 0;;
    }
}

test "get_by_content_id_filters_and_sorts" {
    with entry {
        root spawn GuardTouch;
        r1: dict[str, object] = {};
        r1["id"] = "1";
        r1["content_id"] = "c1";
        r1["parent_id"] = None;
        r1["body"] = "a";
        r1["created_at"] = "2020-01-01";
        r2: dict[str, object] = {};
        r2["id"] = "2";
        r2["content_id"] = "c1";
        r2["parent_id"] = "1";
        r2["body"] = "b";
        r2["created_at"] = "2020-01-02";
        r3: dict[str, object] = {};
        r3["id"] = "3";
        r3["content_id"] = "c2";
        r3["parent_id"] = None;
        r3["body"] = "c";
        r3["created_at"] = "2020-01-03";
        rows: list[dict[str, object]] = [r1, r2, r3];
        st = build_comment_store(rows);
        got = get_by_content_id(st, "c1", 10);
        ids: list[str] = [];
        for it in got {
            ids.append(str(it["id"]));
        }
        assert ids == ["1", "2"];;
    }
}

test "get_replies_collects_subtree" {
    with entry {
        root spawn GuardTouch;
        r1: dict[str, object] = {};
        r1["id"] = "1";
        r1["content_id"] = "c1";
        r1["parent_id"] = None;
        r1["body"] = "a";
        r1["created_at"] = "2020-01-01";
        r2: dict[str, object] = {};
        r2["id"] = "2";
        r2["content_id"] = "c1";
        r2["parent_id"] = "1";
        r2["body"] = "b";
        r2["created_at"] = "2020-01-02";
        r3: dict[str, object] = {};
        r3["id"] = "3";
        r3["content_id"] = "c1";
        r3["parent_id"] = "2";
        r3["body"] = "c";
        r3["created_at"] = "2020-01-03";
        rows: list[dict[str, object]] = [r1, r2, r3];
        st = build_comment_store(rows);
        got = get_replies(st, "1", 10);
        ids: list[str] = [];
        for it in got {
            ids.append(str(it["id"]));
        }
        assert ids == ["2", "3"];;
    }
}

test "get_replies_respects_max_depth" {
    with entry {
        root spawn GuardTouch;
        r1: dict[str, object] = {};
        r1["id"] = "1";
        r1["content_id"] = "c1";
        r1["parent_id"] = None;
        r1["body"] = "a";
        r1["created_at"] = "2020-01-01";
        r2: dict[str, object] = {};
        r2["id"] = "2";
        r2["content_id"] = "c1";
        r2["parent_id"] = "1";
        r2["body"] = "b";
        r2["created_at"] = "2020-01-02";
        r3: dict[str, object] = {};
        r3["id"] = "3";
        r3["content_id"] = "c1";
        r3["parent_id"] = "2";
        r3["body"] = "c";
        r3["created_at"] = "2020-01-03";
        rows: list[dict[str, object]] = [r1, r2, r3];
        st = build_comment_store(rows);
        got = get_replies(st, "1", 1);
        ids: list[str] = [];
        for it in got {
            ids.append(str(it["id"]));
        }
        assert ids == ["2"];;
    }
}
