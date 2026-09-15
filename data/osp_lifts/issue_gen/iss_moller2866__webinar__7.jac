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
