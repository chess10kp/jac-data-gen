"""Comment hard delete: scoped walk vs unscoped FK cascade accounting.

autumn-foundation/autumn#2275 lifted to OSP: comments become CommentNode
archetypes carrying their record scope; reply links become typed
ChildComment edges walked in both directions. The scoped walk prunes at
the record boundary while the unscoped flood follows every edge exactly
like ON DELETE CASCADE does -- the spill between them is the defect.
Deletion is two-phase: collect reach + depth levels with once-only claim
maps, then decrement EVERY affected record's counter and disconnect +
unregister outside the walks.
"""
node CommentNode {
    has cid: str;
    has scope: str;   # "(type,id)" record key
}
edge ChildComment {}

"""Store handle: id resolution plus live per-record counters."""
obj Store {
    has comments: dict[str, CommentNode];
    has counts: dict[str, int];

    def resolve(cid: str) -> CommentNode | None {
        return self.comments.get(cid);
    }
}

def build_store() -> Store {
    return Store(comments={}, counts={});
}

def _register(st: Store, cid: str, scope: str, parent_id: str | None) {
    cn = CommentNode(cid=cid, scope=scope);
    root ++> cn;
    st.comments[cid] = cn;
    if parent_id is not None {
        p = st.resolve(parent_id);
        if p is not None {
            p +>:ChildComment:+> cn;
        }
    }
    cur = st.counts.get(scope, 0);
    st.counts[scope] = cur + 1;
}

"""Framework write path: replies must stay inside the record."""
def add_comment(st: Store, cid: str, scope: str, parent_id: str | None = None) {
    if parent_id is not None {
        p = st.resolve(parent_id);
        if p is None {
            raise KeyError("unknown parent");
        }
        if p.scope != scope {
            raise ValueError("reply crosses record boundary");
        }
    }
    _register(st, cid, scope, parent_id);
}

"""Imported row: may legally carry a CROSS-RECORD parent link."""
def import_comment(st: Store, cid: str, scope: str, parent_id: str | None) {
    if parent_id is not None and st.resolve(parent_id) is None {
        raise KeyError("unknown parent");
    }
    _register(st, cid, scope, parent_id);
}

"""Flood over child edges; prune at other-record nodes when scoped."""
walker ReachFlood {
    has claimed: dict[str, bool];
    has found: list[CommentNode] = [];
    has only_scope: str | None = None;

    can step with CommentNode entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if self.only_scope is not None and here.scope != self.only_scope {
            return;  # prune at the record boundary
        }
        self.found.append(here);
        visit [->:ChildComment:->];
    }
}

def scoped_subtree(st: Store, cid: str) -> list[str] | None {
    start = st.resolve(cid);
    if start is None {
        raise KeyError("unknown comment");
    }
    w = start spawn ReachFlood(claimed={}, only_scope=start.scope);
    out: list[str] = [];
    for n in w.found {
        out.append(n.cid);
    }
    return sorted(out);
}

def unscoped_cascade_reach(st: Store, cid: str) -> list[str] | None {
    start = st.resolve(cid);
    if start is None {
        raise KeyError("unknown comment");
    }
    w = start spawn ReachFlood(claimed={});
    out: list[str] = [];
    for n in w.found {
        out.append(n.cid);
    }
    return sorted(out);
}

"""Rows the DB removes but the scoped query never reported."""
def spill_set(st: Store, cid: str) -> list[str] | None {
    scoped = scoped_subtree(st, cid);
    reach = unscoped_cascade_reach(st, cid);
    if scoped is None or reach is None {
        return None;
    }
    spill: list[str] = [];
    for c in reach {
        if c not in scoped {
            spill.append(c);
        }
    }
    return sorted(spill);
}

"""Depth levels of the same-record replies below ``cid``."""
walker HopSameRecord {
    has claimed: dict[str, bool];
    has scope: str;
    has found: list[CommentNode] = [];

    can step with CommentNode entry {
        kids: list[CommentNode] = [here ->:ChildComment:->];
        for k in kids {
            if k.cid in self.claimed or k.scope != self.scope {
                continue;
            }
            self.claimed[k.cid] = True;
            self.found.append(k);
        }
    }
}

"""Honest two-phase delete with per-record counter repair."""
def hard_delete_subtree(st: Store, cid: str) -> dict {
    start = st.resolve(cid);
    if start is None {
        raise KeyError("unknown comment");
    }
    # Phase 1: collect reach + spill + depth report (read-only walks).
    w = start spawn ReachFlood(claimed={});
    reach = w.found;
    scoped_n = 0;
    spill_n = 0;
    per_record: dict[str, int] = {};
    for n in reach {
        cur = st.counts.get(n.scope, 0);
        if n.scope == start.scope {
            scoped_n += 1;
        } else {
            spill_n += 1;
        }
        per_record[n.scope] = per_record.get(n.scope, 0) + 1;
    }
    claimed: dict[str, bool] = {cid: True};
    levels: list[int] = [];
    frontier: list[CommentNode] = [start];
    while len(frontier) > 0 {
        nxt: list[CommentNode] = [];
        for f in frontier {
            hw = f spawn HopSameRecord(claimed=claimed, scope=start.scope, found=nxt);
            nxt = hw.found;
        }
        if len(nxt) == 0 {
            break;
        }
        levels.append(len(nxt));
        frontier = nxt;
    }
    # Phase 2: sever spill roots, fix counters, unregister everything.
    for n in reach {
        parents: list[CommentNode] = [n <-:ChildComment:<-];
        if len(parents) > 0 {
            par = parents[0];
            if par.cid not in st.comments.keys() or par.cid == cid {
                continue;
            }
            par del ->:ChildComment:-> n;
        }
    }
    for scope_key in per_record.keys() {
        st.counts[scope_key] = st.counts.get(scope_key, 0) - per_record[scope_key];
    }
    for n in reach {
        st.comments.pop(n.cid, None);
    }
    return {"scoped": scoped_n, "total": len(reach), "spill": spill_n, "levels": levels};
}

test "scoped walk vs unscoped cascade reach" {
    st = build_store();
    add_comment(st, "a1", "(ticket,A)");
    add_comment(st, "a2", "(ticket,A)", "a1");
    add_comment(st, "a3", "(ticket,A)", "a2");
    add_comment(st, "b1", "(post,B)");
    try {
        add_comment(st, "bad", "(post,B)", "a1");
        assert False, "expected cross-record reject";
    } except ValueError { assert True; }
    import_comment(st, "x1", "(post,B)", "a2");
    assert scoped_subtree(st, "a1") == ["a1", "a2", "a3"];
    assert unscoped_cascade_reach(st, "a1") == ["a1", "a2", "a3", "x1"];
    assert spill_set(st, "a1") == ["x1"];
}

test "honest delete repairs every affected counter" {
    st = build_store();
    add_comment(st, "r1", "(ticket,A)");
    add_comment(st, "r2", "(ticket,A)", "r1");
    import_comment(st, "x9", "(post,B)", "r2");
    rep = hard_delete_subtree(st, "r1");
    assert rep["scoped"] == 2;
    assert rep["total"] == 3;
    assert rep["spill"] == 1;
    assert st.counts.get("(ticket,A)", 0) == 0;
    assert st.counts.get("(post,B)", 0) == 0;   # corruption repaired
    assert len(st.comments.keys()) == 0;
}

test "clean subtree has no spill and levels pin depth" {
    st = build_store();
    add_comment(st, "c0", "(t,a)");
    for i in [1, 2, 3] {
        pid = "c" + str(i - 1);
        add_comment(st, "c" + str(i), "(t,a)", pid);
    }
    rep = hard_delete_subtree(st, "c0");
    assert rep == {"scoped": 4, "total": 4, "spill": 0, "levels": [1, 1, 1]};
    assert st.counts.get("(t,a)", 0) == 0;
}

test "adversarial diamond terminates once-only" {
    st = build_store();
    add_comment(st, "top", "(t,a)");
    add_comment(st, "l", "(t,a)", "top");
    add_comment(st, "rr", "(t,a)", "top");
    ln = st.resolve("l");
    rn = st.resolve("rr");
    bot = CommentNode(cid="bot", scope="(t,a)");
    root ++> bot;
    st.comments["bot"] = bot;
    ln +>:ChildComment:+> bot;
    rn +>:ChildComment:+> bot;
    assert scoped_subtree(st, "top") == ["bot", "l", "rr", "top"];
    rep = hard_delete_subtree(st, "top");
    assert rep["total"] == 4;
}
