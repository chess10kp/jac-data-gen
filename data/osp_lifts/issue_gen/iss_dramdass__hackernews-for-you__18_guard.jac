"""Lift for dramdass/hackernews-for-you#18 — batch comment fetch and nested tree build."""

node Story {
    has sid: str;
    has title: str;
    has score: int = 0;
    has posted_at: int = 0;
}

node Comment {
    has cid: str;
    has body: str;
    has story_sid: str;
}

edge OnStory {}
edge ReplyTo {}

walker FlatWalker {
    has claimed: dict[str, bool] = {};
    has story_sid: str;
    has rows: list = [];

    can scan_story with Story entry {
        if here.sid in self.claimed {
            skip;
        }
        self.claimed[here.sid] = True;
        print("story ", here.sid);
        kids: list[Comment] = [here ->:OnStory:->][?:Comment];
        for ch in kids {
            visit :0: [ch];
        }
        if len(kids) == 0 {
            disengage;
        }
    }

    can scan_comment with Comment entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.story_sid != self.story_sid {
            disengage;
        }
        row: dict = {};
        row["id"] = here.cid;
        row["body"] = here.body;
        row["story_id"] = here.story_sid;
        row["parent_id"] = None;
        parents: list[Comment] = [here <-:ReplyTo:<-][?:Comment];
        if len(parents) > 0 {
            row["parent_id"] = parents[0].cid;
        }
        self.rows.append(row);
        print("comment ", here.cid);
        kids: list[Comment] = [here ->:ReplyTo:->][?:Comment];
        for kid in kids {
            visit :0: [kid];
        }
        if len(kids) == 0 {
            disengage;
        }
    }
}

def _all_stories(graph_root) -> list[Story] {
    return [graph_root -->][?:Story];
}

def _find_story(graph_root, story_id: str) -> Story | None {
    for st in _all_stories(graph_root) {
        if st.sid == story_id {
            return st;
        }
    }
    return None;
}

def _story_dict(st: Story) -> dict {
    out: dict = {};
    out["id"] = st.sid;
    out["title"] = st.title;
    out["score"] = st.score;
    out["posted_at"] = st.posted_at;
    return out;
}

def _sorted_story_dicts(graph_root) -> list {
    nodes: list[Story] = _all_stories(graph_root);
    out: list = [];
    used: dict[str, bool] = {};
    total: int = len(nodes);
    while len(out) < total {
        best: Story | None = None;
        for st in nodes {
            if st.sid in used {
                continue;
            }
            if best is None {
                best = st;
            } else if st.score > best.score {
                best = st;
            } else if st.score == best.score and st.posted_at > best.posted_at {
                best = st;
            }
        }
        if best is None {
            break;
        }
        used[best.sid] = True;
        out.append(_story_dict(best));
    }
    return out;
}

def list_stories(graph_root, limit: int = 30, offset: int = 0) -> list {
    ranked: list = _sorted_story_dicts(graph_root);
    end: int = offset + limit;
    if offset >= len(ranked) {
        return [];
    }
    if end > len(ranked) {
        end = len(ranked);
    }
    page: list = [];
    i: int = offset;
    while i < end {
        page.append(ranked[i]);
        i = i + 1;
    }
    return page;
}

def get_story(graph_root, story_id: str) -> dict | None {
    st = _find_story(graph_root, story_id);
    if st is None {
        return None;
    }
    return _story_dict(st);
}

def fetch_comments_flat(graph_root, story_id: str) -> list {
    st = _find_story(graph_root, story_id);
    if st is None {
        return [];
    }
    w = st spawn FlatWalker(story_sid=story_id, claimed={});
    rows: list = w.rows;
    return sorted(rows);
}

def _nest_replies(by_parent: dict, parent_key: str) -> list {
    bucket: list = [];
    if parent_key in by_parent {
        bucket = by_parent[parent_key] as list;
    }
    ordered: list = sorted(bucket);
    out: list = [];
    for row in ordered {
        item: dict = {};
        item["id"] = row["id"];
        item["body"] = row["body"];
        item["story_id"] = row["story_id"];
        item["parent_id"] = row["parent_id"];
        child_key: str = row["id"];
        item["replies"] = _nest_replies(by_parent, child_key);
        out.append(item);
    }
    return out;
}

def build_comment_tree(graph_root, story_id: str) -> list {
    flat: list = fetch_comments_flat(graph_root, story_id);
    by_parent: dict = {};
    for row in flat {
        key: str = "none";
        if row["parent_id"] is not None {
            key = row["parent_id"];
        }
        bucket: list = [];
        if key in by_parent {
            bucket = by_parent[key] as list;
        }
        bucket.append(row);
        by_parent[key] = bucket;
    }
    return _nest_replies(by_parent, "none");
}

test "list_stories_rank_and_page" {
    graph_root = root;
    s1 = Story(sid="s1", title="Low", score=5, posted_at=100);
    s2 = Story(sid="s2", title="High", score=20, posted_at=200);
    s3 = Story(sid="s3", title="Mid", score=20, posted_at=150);
    graph_root ++> s1;
    graph_root ++> s2;
    graph_root ++> s3;
    page = list_stories(graph_root, limit=2, offset=0);
    assert (len(page) == 2);
    assert (page[0]["id"] == "s2");
    assert (page[1]["id"] == "s3");
}

test "get_story_found_and_missing" {
    graph_root = root;
    st = Story(sid="s9", title="Found", score=1, posted_at=1);
    graph_root ++> st;
    got = get_story(graph_root, "s9");
    assert (got is not None);
    assert (got["title"] == "Found");
    assert (get_story(graph_root, "missing") is None);
}

test "fetch_comments_flat_sorted" {
    graph_root = root;
    st = Story(sid="st1", title="T", score=1, posted_at=1);
    graph_root ++> st;
    c1 = Comment(cid="c1", body="root", story_sid="st1");
    c2 = Comment(cid="c2", body="child", story_sid="st1");
    st +>:OnStory:+> c1;
    c1 +>:ReplyTo:+> c2;
    rows = fetch_comments_flat(graph_root, "st1");
    assert (len(rows) == 2);
    assert (rows[0]["id"] == "c1");
    assert (rows[1]["id"] == "c2");
    assert (rows[1]["parent_id"] == "c1");
}

test "fetch_comments_flat_unknown_story" {
    graph_root = root;
    assert (len(fetch_comments_flat(graph_root, "nope")) == 0);
}

test "build_comment_tree_nested" {
    graph_root = root;
    st = Story(sid="st2", title="Tree", score=1, posted_at=1);
    graph_root ++> st;
    c1 = Comment(cid="a", body="A", story_sid="st2");
    c2 = Comment(cid="b", body="B", story_sid="st2");
    c3 = Comment(cid="c", body="C", story_sid="st2");
    st +>:OnStory:+> c1;
    c1 +>:ReplyTo:+> c2;
    c1 +>:ReplyTo:+> c3;
    tree = build_comment_tree(graph_root, "st2");
    assert (len(tree) == 1);
    assert (tree[0]["id"] == "a");
    assert (len(tree[0]["replies"]) == 2);
    assert (tree[0]["replies"][0]["id"] == "b");
    assert (tree[0]["replies"][1]["id"] == "c");
}

test "build_comment_tree_empty_story" {
    graph_root = root;
    st = Story(sid="empty", title="E", score=0, posted_at=0);
    graph_root ++> st;
    assert (len(build_comment_tree(graph_root, "empty")) == 0);
}
