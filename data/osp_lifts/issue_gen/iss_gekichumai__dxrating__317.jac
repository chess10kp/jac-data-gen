"""gekichumai/dxrating#317 — moderation cascade over immutable comment thread reach."""

node Comment {
    has cid: str;
}

edge ReplyTo {}

walker ReachReplyWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Comment entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        kids = _sorted_replies(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_replies(nd: Comment) -> list[Comment] {
    kids: list[Comment] = [];
    for ch in [nd ->:ReplyTo:->][?:Comment] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.cid); }
    names = sorted(names);
    ordered: list[Comment] = [];
    for nm in names { for ch in kids { if ch.cid == nm { ordered.append(ch); } } }
    return ordered;
}

def _find_comment(cid: str, store: dict) -> Comment | None {
    nmap = store["nodes"] as dict[str, Comment];
    if cid in nmap { return nmap[cid]; }
    return None;
}

def fresh_moderation_store() -> dict { return {"comments": {}, "replies": {}, "rev": {}, "nodes": {}, "deleted": {}, "events": {}}; }

def register_comment(comment_id: str, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_moderation_store(); }
    (s["comments"] as dict[str, bool])[comment_id] = True;
    outs = s["replies"] as dict[str, list[str]];
    if comment_id not in outs { outs[comment_id] = []; }
    rev = s["rev"] as dict[str, list[str]];
    if comment_id not in rev { rev[comment_id] = []; }
    deleted = s["deleted"] as dict[str, bool];
    deleted[comment_id] = False;
    events = s["events"] as dict[str, list[str]];
    if comment_id not in events { events[comment_id] = []; }
    nd = Comment(cid=comment_id);
    root ++> nd;
    (s["nodes"] as dict[str, Comment])[comment_id] = nd;
    return s;
}

def add_reply_edge(parent_id: str, child_id: str, store: dict) {
    cmap = store["comments"] as dict[str, bool];
    if parent_id not in cmap or child_id not in cmap { raise KeyError("unknown comment id"); }
    if parent_id == child_id { return; }
    par_nd = _find_comment(parent_id, store);
    ch_nd = _find_comment(child_id, store);
    if par_nd is not None and ch_nd is not None {
        seen = False;
        for ex in [par_nd ->:ReplyTo:->][?:Comment] { if ex.cid == child_id { seen = True; } }
        if not seen { par_nd +>:ReplyTo:+> ch_nd; }
    }
    outs = store["replies"] as dict[str, list[str]];
    if parent_id not in outs { outs[parent_id] = []; }
    if child_id not in outs[parent_id] { outs[parent_id].append(child_id); outs[parent_id] = sorted(outs[parent_id]); }
    revs = store["rev"] as dict[str, list[str]];
    if child_id not in revs { revs[child_id] = []; }
    if parent_id not in revs[child_id] { revs[child_id].append(parent_id); revs[child_id] = sorted(revs[child_id]); }
}

def direct_replies(parent_id: str, store: dict) -> list[str] {
    if parent_id not in (store["comments"] as dict) { raise KeyError(parent_id); }
    return list((store["replies"] as dict[str, list[str]]).get(parent_id, []));
}

def reachable_replies(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["comments"] as dict) { raise KeyError(start_id); }
    start_nd = _find_comment(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn ReachReplyWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for cid in w.order { if cid != start_id { reach.append(cid); } }
    return reach;
}

def cascade_mark_deleted(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["comments"] as dict) { raise KeyError(start_id); }
    reach = reachable_replies(start_id, store);
    deleted = store["deleted"] as dict[str, bool];
    events = store["events"] as dict[str, list[str]];
    marked: list[str] = [start_id];
    deleted[start_id] = True;
    ev = events[start_id] as list[str];
    ev.append("delete");
    for cid in reach {
        deleted[cid] = True;
        ev2 = events[cid] as list[str];
        ev2.append("delete");
        marked.append(cid);
    }
    marked = sorted(marked);
    return marked;
}

def moderation_report(comment_id: str, store: dict) -> dict {
    if comment_id not in (store["comments"] as dict) { raise KeyError(comment_id); }
    reach = reachable_replies(comment_id, store);
    direct = direct_replies(comment_id, store);
    deleted = store["deleted"] as dict[str, bool];
    thread_deleted = 0;
    for cid in reach { if deleted.get(cid, False) { thread_deleted += 1; } }
    if deleted.get(comment_id, False) { thread_deleted += 1; }
    return {"direct": direct, "reach": reach, "reach_count": len(reach), "deleted": deleted.get(comment_id, False), "thread_deleted_count": thread_deleted};
}
