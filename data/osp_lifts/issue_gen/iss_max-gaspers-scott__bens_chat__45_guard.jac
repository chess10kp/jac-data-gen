"""Message subtree batch query and client retreeify — max-gaspers-scott/bens_chat#45."""

node Message {
    has mid: str;
    has parent_ref: str = "";
    has sent_at: str = "";
    has body: str = "";
}

edge Reply {}

def msg_row(msg: Message, depth: int) -> dict {
    return {
        "message_id": msg.mid,
        "parent_id": msg.parent_ref,
        "sent_at": msg.sent_at,
        "body": msg.body,
        "depth": depth,
    };
}

def cmp_rows(a: dict, b: dict) -> int {
    da = a["depth"] as int;
    db = b["depth"] as int;
    if da < db {
        return -1;
    }
    if da > db {
        return 1;
    }
    sa = a["sent_at"] as str;
    sb = b["sent_at"] as str;
    if sa < sb {
        return -1;
    }
    if sa > sb {
        return 1;
    }
    return 0;
}

def sort_rows(rows: list) -> list {
    out: list = [];
    for r in rows {
        out.append(r);
    }
    n = len(out);
    i = 0;
    while i < n {
        j = i + 1;
        while j < n {
            if cmp_rows(out[j] as dict, out[i] as dict) < 0 {
                tmp = out[i];
                out[i] = out[j];
                out[j] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
    return out;
}

def sort_msgs(nodes: list[Message]) -> list[Message] {
    out: list[Message] = [];
    for nd in nodes {
        out.append(nd);
    }
    n = len(out);
    i = 0;
    while i < n {
        j = i + 1;
        while j < n {
            if out[j].sent_at < out[i].sent_at {
                tmp = out[i];
                out[i] = out[j];
                out[j] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
    return out;
}

def materialize(store: dict[str, dict], focus_id: str) -> Message | None {
    nodes: dict[str, Message] = {};
    mids: list[str] = sorted(store);
    for mid in mids {
        row = store[mid] as dict;
        pid = "";
        if "parent_id" in row {
            pid = row["parent_id"] as str;
        }
        sat = "";
        if "sent_at" in row {
            sat = row["sent_at"] as str;
        }
        bod = "";
        if "body" in row {
            bod = row["body"] as str;
        }
        nd = Message(mid=mid, parent_ref=pid, sent_at=sat, body=bod);
        nodes[mid] = nd;
        root ++> nd;
    }
    focus: Message | None = None;
    for mid in mids {
        nd = nodes[mid];
        if mid == focus_id {
            focus = nd;
        }
        pr = nd.parent_ref;
        if pr != "" {
            if pr in nodes {
                par = nodes[pr];
                par +>:Reply:+> nd;
            }
        }
        row = store[mid] as dict;
        if "extra_replies" in row {
            extras = row["extra_replies"] as list;
            for xr in extras {
                xid = xr as str;
                if xid in nodes {
                    xp = nodes[xid];
                    xp +>:Reply:+> nd;
                }
            }
        }
    }
    return focus;
}

walker SubtreeWalker {
    has claimed: dict[str, bool] = {};
    has origin: str = "";
    has max_depth: int = 1;
    has walk_depth: int = 0;
    has collected: list = [];

    can descend with Message entry {
        if here.mid in self.claimed {
            skip;
        }
        self.claimed[here.mid] = True;

        if here.mid == self.origin {
            print(["subtree_origin", here.mid]);
            kids: list[Message] = [];
            for ch in [here ->:Reply:->][?:Message] {
                kids.append(ch);
            }
            kids = sort_msgs(kids);
            for kid in kids {
                self.walk_depth = 1;
                visit :0: [kid];
            }
            skip;
        }

        self.collected.append(msg_row(here, self.walk_depth));
        print(["subtree_visit", here.mid, self.walk_depth]);
        if self.walk_depth < self.max_depth {
            kids2: list[Message] = [];
            for ch in [here ->:Reply:->][?:Message] {
                kids2.append(ch);
            }
            kids2 = sort_msgs(kids2);
            nd = self.walk_depth + 1;
            for kid in kids2 {
                self.walk_depth = nd;
                visit :0: [kid];
            }
        }
    }
}

def query_message_subtree(parent_id: str, max_depth: int, store: dict[str, dict]) -> list {
    if parent_id not in store {
        return [];
    }
    anchor = materialize(store, parent_id);
    if anchor is None {
        return [];
    }
    w = anchor spawn SubtreeWalker(origin=parent_id, max_depth=max_depth, claimed={}, collected=[]);
    return sort_rows(w.collected);
}

def nest_node(msg: Message, child_trees: dict[str, dict]) -> dict {
    kids_out: list = [];
    kid_nodes: list[Message] = [];
    for ch in [msg ->:Reply:->][?:Message] {
        kid_nodes.append(ch);
    }
    kid_nodes = sort_msgs(kid_nodes);
    for kn in kid_nodes {
        if kn.mid in child_trees {
            kids_out.append(child_trees[kn.mid]);
        }
    }
    return {
        "message_id": msg.mid,
        "parent_id": msg.parent_ref,
        "sent_at": msg.sent_at,
        "body": msg.body,
        "children": kids_out,
    };
}

walker TreeifyWalker {
    has claimed: dict[str, bool] = {};
    has built: dict[str, dict] = {};

    can assemble with Message entry {
        if here.mid in self.claimed {
            skip;
        }
        self.claimed[here.mid] = True;
        kids: list[Message] = [];
        for ch in [here ->:Reply:->][?:Message] {
            kids.append(ch);
        }
        kids = sort_msgs(kids);
        for kid in kids {
            visit :0: [kid];
        }
        self.built[here.mid] = nest_node(here, self.built);
        print(["treeify_visit", here.mid]);
    }
}

def retreeify_messages(flat_rows: list) -> dict | None {
    if len(flat_rows) == 0 {
        return None;
    }
    store: dict[str, dict] = {};
    for row in flat_rows {
        r = row as dict;
        mid = r["message_id"] as str;
        store[mid] = r;
    }
    root_id: str = "";
    root_count: int = 0;
    mids: list[str] = sorted(store);
    for mid in mids {
        r = store[mid] as dict;
        pid = "";
        if "parent_id" in r {
            pid = r["parent_id"] as str;
        }
        if pid == "" or pid not in store {
            root_id = mid;
            root_count += 1;
        }
    }
    if root_count != 1 {
        return None;
    }
    anchor = materialize(store, root_id);
    if anchor is None {
        return None;
    }
    w = anchor spawn TreeifyWalker(claimed={}, built={});
    if root_id in w.built {
        return w.built[root_id];
    }
    return None;
}

def load_thread_tree(store: dict[str, dict], thread_root_id: str, max_depth: int) -> dict | None {
    if thread_root_id not in store {
        return None;
    }
    rows = query_message_subtree(thread_root_id, max_depth, store);
    r0 = store[thread_root_id] as dict;
    pid0 = "";
    if "parent_id" in r0 {
        pid0 = r0["parent_id"] as str;
    }
    sat0 = "";
    if "sent_at" in r0 {
        sat0 = r0["sent_at"] as str;
    }
    bod0 = "";
    if "body" in r0 {
        bod0 = r0["body"] as str;
    }
    full_rows: list = [];
    full_rows.append({
        "message_id": thread_root_id,
        "parent_id": pid0,
        "sent_at": sat0,
        "body": bod0,
        "depth": 0,
    });
    for rw in rows {
        full_rows.append(rw);
    }
    return retreeify_messages(full_rows);
}

test "max_depth_truncates_recursive_cte" {
    store: dict[str, dict] = {
        "p": {"parent_id": "", "sent_at": "a", "body": ""},
        "c1": {"parent_id": "p", "sent_at": "a", "body": ""},
        "c2": {"parent_id": "c1", "sent_at": "b", "body": ""},
    };
    rows1 = query_message_subtree("p", 1, store);
    depths1: list[int] = [];
    for r in rows1 {
        depths1.append(r["depth"] as int);
    }
    assert depths1 == [1];
    rows2 = query_message_subtree("p", 2, store);
    depths2: list[int] = [];
    for r in rows2 {
        depths2.append(r["depth"] as int);
    }
    assert depths2 == [1, 2];
}

test "retreeify_flat_list_nested_children" {
    flat: list = [
        {"message_id": "p", "parent_id": "", "sent_at": "a", "body": ""},
        {"message_id": "c1", "parent_id": "p", "sent_at": "b", "body": ""},
        {"message_id": "c2", "parent_id": "c1", "sent_at": "c", "body": ""},
    ];
    tree = retreeify_messages(flat);
    assert tree is not None;
    kids = tree["children"] as list;
    assert len(kids) == 1;
    c1tree = kids[0] as dict;
    assert c1tree["message_id"] as str == "c1";
    gkids = c1tree["children"] as list;
    assert len(gkids) == 1;
    assert (gkids[0] as dict)["message_id"] as str == "c2";
}

test "load_thread_tree_depth_sent_at_order" {
    store: dict[str, dict] = {
        "p": {"parent_id": "", "sent_at": "1", "body": ""},
        "a": {"parent_id": "p", "sent_at": "2", "body": ""},
        "b": {"parent_id": "p", "sent_at": "3", "body": ""},
    };
    tree = load_thread_tree(store, "p", 2);
    assert tree is not None;
    kids = tree["children"] as list;
    assert len(kids) == 2;
    assert (kids[0] as dict)["message_id"] as str == "a";
    assert (kids[1] as dict)["message_id"] as str == "b";
}

test "query_unknown_parent_empty" {
    store: dict[str, dict] = {};
    rows = query_message_subtree("missing", 2, store);
    assert rows == [];
}

test "retreeify_empty_none" {
    flat: list = [];
    tree = retreeify_messages(flat);
    assert tree is None;
}
