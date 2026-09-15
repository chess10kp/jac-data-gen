"""drizzle-team/drizzle-orm#1215 — recursive relational with depth."""

node Post {
    has id: int;
    has body: str;
    has kind: str;
}

node PostStore {
    has by_id: dict[int, Post] = {};
}

edge ParentOf {}

def posts_sorted_by_id(items: list[Post]) -> list[Post] {
    ids: list[int] = [];
    for p in items {
        ids.append(p.id);
    }
    sorted_ids = sorted(ids);
    out: list[Post] = [];
    for sid in sorted_ids {
        for p in items {
            if p.id == sid {
                out.append(p);
            }
        }
    }
    return out;
}

def new_store -> PostStore {
    st = PostStore(by_id={});
    root ++> st;
    return st;
}

def add_post(
    store: PostStore,
    post_id: int,
    body: str,
    kind: str,
    parent_id: int | None = None
) {
    nd = Post(id=post_id, body=body, kind=kind);
    store.by_id[post_id] = nd;
    root ++> nd;
    if parent_id is not None {
        if parent_id in store.by_id {
            par = store.by_id[parent_id];
            par +>:ParentOf:+> nd;
        }
    }
}

walker TreeWalker {
    has depth_limit: int = 0;
    has level: int = 0;
    has claimed: dict[str, bool] = {};
    has result: dict[str, any] = {};

    can build with Post entry {
        key = str(here.id);
        if key in self.claimed {
            skip;
        }
        self.claimed[key] = True;
        print ["tree_walk", here.id, self.level];

        row: dict[str, any] = {};
        row["id"] = here.id;
        row["body"] = here.body;
        row["kind"] = here.kind;
        row["children"] = [];

        if self.depth_limit != 0 and self.level >= self.depth_limit {
            self.result = row;
            disengage;
        }

        raw_kids: list[Post] = [here ->:ParentOf:->][?:Post];
        kids = posts_sorted_by_id(raw_kids);
        child_level = self.level + 1;
        child_rows: list[dict[str, any]] = [];
        for ch in kids {
            ch_key = str(ch.id);
            if ch_key in self.claimed {
                continue;
            }
            sub = ch spawn TreeWalker(
                depth_limit=self.depth_limit,
                level=child_level,
                claimed=self.claimed
            );
            child_rows.append(sub.result);
        }
        row["children"] = child_rows;
        self.result = row;
    }
}

def find_first_with_children(
    store: PostStore,
    post_id: int,
    depth: int = 0
) -> dict[str, any] | None {
    if post_id not in store.by_id {
        return None;
    }
    anchor = store.by_id[post_id];
    w = anchor spawn TreeWalker(depth_limit=depth, level=0, claimed={});
    return w.result;
}

test "unknown_post_returns_none" {
    store = new_store();
    got = find_first_with_children(store, 404);
    assert got is None;
}

test "single_post_empty_children" {
    store = new_store();
    add_post(store, 1, "hello", "post");
    got = find_first_with_children(store, 1);
    assert got["id"] == 1;
    assert got["body"] == "hello";
    assert got["kind"] == "post";
    assert len(got["children"]) == 0;
}

test "children_sorted_by_id" {
    store = new_store();
    add_post(store, 1, "root", "post");
    add_post(store, 30, "late", "comment", 1);
    add_post(store, 10, "early", "comment", 1);
    got = find_first_with_children(store, 1);
    ch = got["children"];
    assert len(ch) == 2;
    assert ch[0]["id"] == 10;
    assert ch[1]["id"] == 30;
}

test "depth_one_truncates_grandchildren" {
    store = new_store();
    add_post(store, 1, "root", "post");
    add_post(store, 2, "child", "comment", 1);
    add_post(store, 3, "grand", "comment", 2);
    got = find_first_with_children(store, 1, 1);
    assert got["children"][0]["id"] == 2;
    assert len(got["children"][0]["children"]) == 0;
}

test "depth_zero_expands_full_tree" {
    store = new_store();
    add_post(store, 1, "root", "post");
    add_post(store, 2, "child", "comment", 1);
    add_post(store, 3, "grand", "comment", 2);
    got = find_first_with_children(store, 1, 0);
    assert got["children"][0]["children"][0]["id"] == 3;
}

test "orphan_parent_id_still_stores_post" {
    store = new_store();
    add_post(store, 9, "loner", "comment", 99);
    got = find_first_with_children(store, 9);
    assert got["id"] == 9;
    assert len(got["children"]) == 0;
}
