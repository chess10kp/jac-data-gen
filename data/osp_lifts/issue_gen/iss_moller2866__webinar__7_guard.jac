"""moller2866/webinar#7 — threaded comments flat-to-tree assembly."""

node Comment {
    has cid: str;
    has post_id: str;
    has parent_id: str = "";
    has author_display_name: str = "";
    has body: str = "";
    has visual_depth: int = 0;
    has built: dict = {};
}

edge Reply {}

walker TreeBuild {
    has max_depth: int = 5;
    has cur_depth: int = 1;
    has claimed: dict[str, bool] = {};

    can step with Comment entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        vd: int = self.cur_depth;
        if vd > self.max_depth { vd = self.max_depth; }
        here.visual_depth = vd;
        kids_raw: list[Comment] = [here ->:Reply:->][?:Comment];
        kids: list[Comment] = sort_comments(kids_raw);
        for kid in kids {
            kid spawn TreeBuild(
                max_depth=self.max_depth,
                cur_depth=self.cur_depth + 1,
                claimed=self.claimed
            );
        }
        replies: list[dict] = [];
        for kid in kids {
            replies.append(kid.built);
        }
        here.built = {
            "id": here.cid,
            "post_id": here.post_id,
            "parent_id": here.parent_id,
            "author_display_name": here.author_display_name,
            "body": here.body,
            "visual_depth": vd,
            "replies": replies
        };
        print(here.cid, vd);
    }
}

def make_comment(
    cid: str,
    post_id: str,
    parent_id: str,
    author_display_name: str,
    body: str
) -> dict {
    return {
        "id": cid,
        "post_id": post_id,
        "parent_id": parent_id,
        "author_display_name": author_display_name,
        "body": body
    };
}

def index_comments(comments: list[dict]) -> dict[str, dict] {
    idx: dict[str, dict] = {};
    for c in comments {
        idx[c["id"]] = c;
    }
    return idx;
}

def validate_parent(index: dict[str, dict], parent_id: str, post_id: str) -> bool {
    if parent_id == "" { return True; }
    if parent_id not in index { return False; }
    return index[parent_id]["post_id"] == post_id;
}

def sort_comments(nodes: list[Comment]) -> list[Comment] {
    out: list[Comment] = [];
    for nd in nodes { out.append(nd); }
    n: int = len(out);
    i: int = 0;
    while i < n {
        j: int = i + 1;
        while j < n {
            if out[j].cid < out[i].cid {
                tmp: Comment = out[i];
                out[i] = out[j];
                out[j] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
    return out;
}

def ingest_flat(comments: list[dict]) -> dict[str, Comment] {
    idx: dict[str, Comment] = {};
    for row in comments {
        nd = Comment(
            cid=row["id"],
            post_id=row["post_id"],
            parent_id=row["parent_id"],
            author_display_name=row["author_display_name"],
            body=row["body"]
        );
        root ++> nd;
        idx[row["id"]] = nd;
    }
    for row in comments {
        pid: str = row["parent_id"];
        if pid == "" { continue; }
        if pid not in idx { continue; }
        par: Comment = idx[pid] as Comment;
        ch: Comment = idx[row["id"]] as Comment;
        par +>:Reply:+> ch;
    }
    return idx;
}

def find_root_nodes(comments: list[dict], idx: dict[str, Comment]) -> list[Comment] {
    roots: list[Comment] = [];
    for row in comments {
        pid: str = row["parent_id"];
        if pid == "" {
            roots.append(idx[row["id"]] as Comment);
        } elif pid not in idx {
            roots.append(idx[row["id"]] as Comment);
        }
    }
    return roots;
}

def assemble_tree(comments: list[dict], max_depth: int = 5) -> list[dict] {
    idx: dict[str, Comment] = ingest_flat(comments);
    claimed: dict[str, bool] = {};
    root_nodes: list[Comment] = find_root_nodes(comments, idx);
    sorted_roots: list[Comment] = sort_comments(root_nodes);
    out: list[dict] = [];
    for rn in sorted_roots {
        rn spawn TreeBuild(max_depth=max_depth, cur_depth=1, claimed=claimed);
        out.append(rn.built);
    }
    return out;
}

with entry {
    rows: list[dict] = [];
    rows.append(make_comment("1", "p1", "", "Alice", "campfire"));
    rows.append(make_comment("2", "p1", "1", "Bob", "reply"));
    assemble_tree(rows, 5);
}

test "assemble_single_root_reply" {
    rows: list[dict] = [];
    rows.append(make_comment("1", "p1", "", "Alice", "root"));
    rows.append(make_comment("2", "p1", "1", "Bob", "reply"));
    tree = assemble_tree(rows, 5);
    assert len(tree) == 1;;
    assert tree[0]["id"] == "1";;
    reps: list = tree[0]["replies"] as list;
    assert len(reps) == 1;;
    assert reps[0]["id"] == "2";;
    assert reps[0]["visual_depth"] == 2;;
}

test "top_level_sorted_by_id" {
    rows: list[dict] = [];
    rows.append(make_comment("b", "p1", "", "x", "y"));
    rows.append(make_comment("a", "p1", "", "x", "y"));
    tree = assemble_tree(rows, 5);
    assert len(tree) == 2;;
    assert tree[0]["id"] == "a";;
    assert tree[1]["id"] == "b";;
}

test "orphan_parent_promoted_root" {
    rows: list[dict] = [];
    rows.append(make_comment("1", "p1", "", "a", "b"));
    rows.append(make_comment("2", "p1", "missing", "a", "b"));
    tree = assemble_tree(rows, 5);
    ids: list[str] = [];
    for r in tree { ids.append(r["id"]); }
    ids = sorted(ids);
    assert ids == ["1", "2"];;
}

test "validate_parent_wrong_post" {
    rows: list[dict] = [];
    rows.append(make_comment("1", "p1", "", "a", "b"));
    rows.append(make_comment("2", "p2", "", "a", "b"));
    idx = index_comments(rows);
    ok = validate_parent(idx, "2", "p1");
    assert ok is False;;
}

test "visual_depth_capped_at_five" {
    rows: list[dict] = [];
    rows.append(make_comment("1", "p1", "", "a", "b"));
    rows.append(make_comment("2", "p1", "1", "a", "b"));
    rows.append(make_comment("3", "p1", "2", "a", "b"));
    rows.append(make_comment("4", "p1", "3", "a", "b"));
    rows.append(make_comment("5", "p1", "4", "a", "b"));
    rows.append(make_comment("6", "p1", "5", "a", "b"));
    rows.append(make_comment("7", "p1", "6", "a", "b"));
    tree = assemble_tree(rows, 5);
    assert len(tree) == 1;;
    assert tree[0]["id"] == "1";;
    assert tree[0]["visual_depth"] == 1;;
    cur: dict = tree[0] as dict;
    step: int = 0;
    while step < 6 {
        reps: list = cur["replies"] as list;
        assert len(reps) == 1;;
        cur = reps[0] as dict;
        step += 1;
    }
    assert cur["id"] == "7";;
    assert cur["visual_depth"] == 5;;
}
