# Topic/Session pagination, grouping, and refresh semantics.
# CherryHQ/cherry-studio#16994

node Topic {
    has tid: str;
    has title: str;
    has owner_id: str;
    has pinned: bool = False;
    has seq: int = 0;
}

node Session {
    has sid: str;
    has topic_id: str;
    has agent_id: str;
    has updated_at: int = 0;
}

node Cursor {
    has cid: str;
    has topic_tid: str;
    has stale: bool = False;
}

edge CursorNext {}
edge TopicSession {}

def find_topic(graph_root: Topic, tid: str) -> Topic | None {
    for nd in [graph_root-->] {
        if nd is Topic and nd.tid == tid {
            return nd;
        }
    }
    return None;
}

def find_cursor(graph_root: Cursor, cid: str) -> Cursor | None {
    for nd in [graph_root-->] {
        if nd is Cursor and nd.cid == cid {
            return nd;
        }
    }
    return None;
}

def topic_page(cursor_after: str | None, limit: int, graph_root: Topic) -> list[str] {
    rows: list[str] = [];
    start: bool = False;
    if cursor_after is None {
        start = True;
    }
    for nd in [graph_root-->] {
        if nd is Topic {
            if not start {
                if nd.tid == cursor_after {
                    start = True;
                }
                continue;
            }
            if len(rows) >= limit {
                break;
            }
            rows.append(nd.tid);
        }
    }
    return rows;
}

def group_by_owner(topic_ids: list[str], graph_root: Topic) -> dict[str, list[str]] {
    grouped: dict[str, list[str]] = {};
    for tid in topic_ids {
        t = find_topic(graph_root, tid);
        if t is None {
            continue;
        }
        oid = t.owner_id;
        if oid not in grouped {
            grouped[oid] = [];
        }
        grouped[oid].append(tid);
    }
    return grouped;
}

def sessions_for_topic(topic_id: str, graph_root: Topic) -> list[str] {
    out: list[str] = [];
    t = find_topic(graph_root, topic_id);
    if t is None {
        return out;
    }
    for ch in [t ->:TopicSession:->][?:Session] {
        out.append(ch.sid);
    }
    out = sorted(out);
    return out;
}

walker StaleWalker {
    has written_tid: str;
    has claimed: dict[str, bool] = {};
    has stale_ids: list[str] = [];

    can step with Cursor entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.topic_tid == self.written_tid {
            here.stale = True;
            self.stale_ids.append(here.cid);
        }
        kids: list[Cursor] = [here ->:CursorNext:->][?:Cursor];
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def cascade_invalidate(written_topic_id: str, cursor_root: Cursor) -> list[str] {
    w = cursor_root spawn StaleWalker(
        written_tid=written_topic_id,
        claimed={},
        stale_ids=[]
    );
    out: list[str] = w.stale_ids;
    out = sorted(out);
    print out;
    return out;
}

def build_fixture -> Topic {
    graph_root = Topic(tid="__root__", title="", owner_id="", seq=-1);
    t_a = Topic(tid="t_a", title="Alpha", owner_id="owner_1", seq=30);
    t_b = Topic(tid="t_b", title="Beta", owner_id="owner_2", seq=20);
    t_c = Topic(tid="t_c", title="Gamma", owner_id="owner_1", seq=10);
    graph_root ++> t_a;
    graph_root ++> t_b;
    graph_root ++> t_c;
    s1 = Session(sid="s1", topic_id="t_a", agent_id="ag1", updated_at=5);
    s2 = Session(sid="s2", topic_id="t_a", agent_id="ag2", updated_at=3);
    t_a +>:TopicSession:+> s1;
    t_a +>:TopicSession:+> s2;
    return graph_root;
}

def build_cursor_fixture -> Cursor {
    cursor_root = Cursor(cid="__croot__", topic_tid="__none__");
    c1 = Cursor(cid="c1", topic_tid="t_a");
    c2 = Cursor(cid="c2", topic_tid="t_b");
    c3 = Cursor(cid="c3", topic_tid="t_c");
    cursor_root ++> c1;
    c1 +>:CursorNext:+> c2;
    c1 +>:CursorNext:+> c3;
    c3 +>:CursorNext:+> c2;
    return cursor_root;
}

with entry {
    graph_root = build_fixture();
    cursor_root = build_cursor_fixture();
    root spawn StaleWalker(written_tid="t_b", claimed={}, stale_ids=[]);
    page = topic_page(None, 2, graph_root);
    print page;
    grouped = group_by_owner(["t_c", "t_a", "t_b", "missing"], graph_root);
    print grouped;
    stale = cascade_invalidate("t_b", cursor_root);
    print stale;
    sess = sessions_for_topic("t_a", graph_root);
    print sess;
}

test "topic_page_first_page" {
    graph_root = build_fixture();
    page = topic_page(None, 2, graph_root);
    assert page == ["t_a", "t_b"];
}

test "topic_page_after_cursor" {
    graph_root = build_fixture();
    page = topic_page("t_a", 10, graph_root);
    assert page == ["t_b", "t_c"];
}

test "group_by_owner_preserves_input_order" {
    graph_root = build_fixture();
    grouped = group_by_owner(["t_c", "t_a", "t_b", "missing"], graph_root);
    assert grouped["owner_1"] == ["t_c", "t_a"];
    assert grouped["owner_2"] == ["t_b"];
}

test "sessions_for_topic_sorted" {
    graph_root = build_fixture();
    sess = sessions_for_topic("t_a", graph_root);
    assert sess == ["s1", "s2"];
}

test "sessions_for_unknown_topic_empty" {
    graph_root = build_fixture();
    sess = sessions_for_topic("missing", graph_root);
    assert sess == [];
}

test "cascade_invalidate_marks_matching_cursors" {
    cursor_root = build_cursor_fixture();
    stale = cascade_invalidate("t_b", cursor_root);
    assert stale == ["c2"];
    c2 = find_cursor(cursor_root, "c2");
    assert c2 is not None;
    assert c2.stale is True;
}
