"""Guard: serrrfirat/bottega#165."""

node WorkItem { has iid: str; has status: str = "open"; }
edge DependsOn {}

obj WorkQueue { has items: dict[str, WorkItem] = {}; }

walker DependentCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can step with WorkItem entry {
        if here.iid in self.claimed { skip; }
        self.claimed[here.iid] = True;
        self.found.append(here.iid);
        visit [->:DependsOn:->][?:WorkItem] else { disengage; };
    }
}

def load_queue(
    items: list[str],
    depends: list[tuple[str, str]],
    status: dict[str, str],
) -> WorkQueue {
    q = WorkQueue();
    for iid in items {
        st = status.get(iid, "open");
        nd = WorkItem(iid=iid, status=st);
        root ++> nd;
        q.items[iid] = nd;
    }
    for (child, parent) in depends {
        c = q.items.get(child, None);
        p = q.items.get(parent, None);
        if c is not None and p is not None { p +>:DependsOn:+> c; }
    }
    return q;
}

def claimable(q: WorkQueue, item_id: str) -> bool {
    nd = q.items.get(item_id, None);
    if nd is None { return False; }
    if nd.status != "open" { return False; }
    parents = [nd <-:DependsOn:<-][?:WorkItem];
    if len(parents) == 0 { return True; }
    return parents[0].status == "done";
}

def propagate_block(q: WorkQueue, item_id: str) -> list[str] {
    nd = q.items.get(item_id, None);
    if nd is None { raise KeyError("unknown item"); }
    nd.status = "blocked";
    w = nd spawn DependentCollect(claimed={}, found=[]);
    changed: list[str] = [item_id];
    for dep_id in w.found {
        if dep_id == item_id { continue; }
        dep = q.items.get(dep_id, None);
        if dep is None { continue; }
        if dep.status != "blocked" and dep.status != "aborted" {
            dep.status = "blocked";
            changed.append(dep_id);
        }
    }
    return sorted(changed);
}

def mark_done(q: WorkQueue, item_id: str) {
    nd = q.items.get(item_id, None);
    if nd is not None { nd.status = "done"; }
}

test "claim waits on dependency done" {
    q = load_queue(
        ["a", "b", "c"],
        [("b", "a"), ("c", "b")],
        {"a": "open", "b": "open", "c": "open"},
    );
    assert claimable(q, "a") is True;
    assert claimable(q, "b") is False;
    mark_done(q, "a");
    assert claimable(q, "b") is True;
}

test "block propagates to dependents" {
    q = load_queue(
        ["a", "b", "c"],
        [("b", "a"), ("c", "b")],
        {"a": "done", "b": "open", "c": "open"},
    );
    assert propagate_block(q, "b") == ["b", "c"];
    assert q.items["c"].status == "blocked";
}

test "chain of three end to end" {
    q = load_queue(
        ["s1", "s2", "s3"],
        [("s2", "s1"), ("s3", "s2")],
        {"s1": "open", "s2": "open", "s3": "open"},
    );
    mark_done(q, "s1");
    assert claimable(q, "s2") is True;
    mark_done(q, "s2");
    assert claimable(q, "s3") is True;
}

test "unknown item raises" {
    q = load_queue(["solo"], [], {"solo": "open"});
    try {
        propagate_block(q, "ghost");
        assert False;
    } except KeyError {
        assert True;
    }
}

test "cycle collect once only" {
    q = load_queue(["a", "b"], [], {"a": "open", "b": "open"});
    q.items["a"] +>:DependsOn:+> q.items["b"];
    q.items["b"] +>:DependsOn:+> q.items["a"];
    w = q.items["a"] spawn DependentCollect(claimed={}, found=[]);
    assert sorted(w.found) == ["a", "b"];
}
