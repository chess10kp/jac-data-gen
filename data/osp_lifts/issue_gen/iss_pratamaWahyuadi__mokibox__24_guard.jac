# pratamaWahyuadi/mokibox#24 — comments with replies and cascade delete
node Video {
    has vid: str;
    has status: str = "READY";
    has comments_count: int = 0;
}
node Comment {
    has cid: str;
    has vid: str;
    has content: str;
    has author: str;
    has created_at: int;
    has deleted: bool = False;
}
node Clock { has n: int = 1; }
edge REPLY_TO {}

# clock lives on a fresh-per-graph node, not a mutable glob
def clock_node() -> Clock {
    for ck in [root ->][?:Clock] {
        return ck;
    }
    nd = Clock();
    root ++> nd;
    return nd;
}

def now() -> int {
    ck = clock_node();
    ck.n += 1;
    return ck.n - 1;
}

def find_video(vid: str) -> Video | None {
    for v in [root ->][?:Video] {
        if v.vid == vid { return v; }
    }
    return None;
}

def find_comment(cid: str) -> Comment | None {
    for c in [root ->][?:Comment] {
        if c.cid == cid { return c; }
    }
    return None;
}

walker InsertComment {
    has vid: str;
    has content: str;
    has parent_id: str | None = None;
    has author: str;
    has out: Comment | None = None;
    has ok: bool = False;

    can start with root entry {
        v: Video | None = find_video(self.vid);
        if v is None or v.status != "READY" { disengage; }
        if len(self.content) < 1 or len(self.content) > 1000 { disengage; }
        parent: Comment | None = None;
        if self.parent_id is not None {
            parent = find_comment(self.parent_id);
            if parent is None { disengage; }
        }
        c = Comment(cid="c" + str(now()), vid=self.vid, content=self.content,
                    author=self.author, created_at=now());
        root ++> c;
        if parent is not None {
            parent +>:REPLY_TO:+> c;
        } else {
            root +>:REPLY_TO:+> c;
        }
        v.comments_count += 1;
        self.out = c;
        self.ok = True;
    }
}

walker CountSubtree {
    has claimed: dict[str, bool] = {};
    has total: int = 0;

    can step with Comment entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.total += 1;
        visit [here ->:REPLY_TO:->];
    }
}

walker CascadeDelete {
    has claimed: dict[str, bool] = {};
    has removed: list[str] = [];

    can step with Comment entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        here.deleted = True;
        self.removed.append(here.cid);
        visit [here ->:REPLY_TO:->];
    }
}

def insert_comment(vid: str, content: str, author: str,
                   parent_id: str | None = None) -> Comment | None {
    w = root spawn InsertComment(vid=vid, content=content,
                                 parent_id=parent_id, author=author, claimed={});
    if w.ok { return w.out; }
    return None;
}

def list_comments(vid: str) -> list[Comment] {
    res: list[Comment] = [];
    for c in [root ->][?:Comment] {
        if c.vid == vid and not c.deleted {
            res.append(c);
        }
    }
    # insertion sort, newest first
    out: list[Comment] = [];
    for c in res {
        idx: int = 0;
        for i in range(len(out)) {
            if out[i].created_at >= c.created_at {
                idx = i + 1;
            }
        }
        out.insert(idx, c);
    }
    return out;
}

def delete_comment(cid: str) -> int {
    target: Comment | None = find_comment(cid);
    if target is None or target.deleted { return -1; }
    cw = target spawn CountSubtree(claimed={});
    target spawn CascadeDelete(claimed={});
    v: Video | None = find_video(target.vid);
    if v is not None {
        v.comments_count -= cw.total;
    }
    return cw.total;
}

test "insert_and_list" {
    v = Video(vid="v1");
    root ++> v;
    a = insert_comment("v1", "hello", "ann");
    assert a is not None;
    b = insert_comment("v1", "hi again", "bob", parent_id=a.cid);
    assert b is not None;
    c = insert_comment("v1", "another", "cat");
    assert c is not None;
    ls = list_comments("v1");
    assert len(ls) == 3;
    assert ls[0].cid == c.cid;
    assert ls[1].cid == a.cid;
    assert ls[2].cid == b.cid;
    vv = find_video("v1");
    assert vv.comments_count == 3;
}

test "insert_unknown_video" {
    assert insert_comment("nope", "x", "y") is None;
}

test "cascade_delete" {
    v = Video(vid="v2");
    root ++> v;
    a = insert_comment("v2", "root", "u1");
    r1 = insert_comment("v2", "r1", "u2", parent_id=a.cid);
    r2 = insert_comment("v2", "r2", "u3", parent_id=a.cid);
    assert r1 is not None and r2 is not None;
    n = delete_comment(a.cid);
    assert n == 3;
    assert len(list_comments("v2")) == 0;
    vv = find_video("v2");
    assert vv.comments_count == 0;
}

test "delete_twice_returns_minus_one" {
    v = Video(vid="v3");
    root ++> v;
    a = insert_comment("v3", "x", "u");
    assert delete_comment(a.cid) == 1;
    assert delete_comment(a.cid) == -1;
}

test "delete_unknown_returns_minus_one" {
    assert delete_comment("ghost") == -1;
}
