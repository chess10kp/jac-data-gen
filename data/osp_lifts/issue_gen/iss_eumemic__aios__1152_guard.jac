"""Task-tree cancel cascade with edge-owned lifetime, lifted to OSP.

Tasks are ``Task`` nodes; parent ownership becomes typed ``Owns``
edges from parent to child. The cascade keeps the source's two-phase
protocol: a collect sweep gathers active descendants once per node
(explicit seen guard -- jac 0.36.1 has no built-in dedup), then the
façade applies revocation outside the walk. Fulfilled tasks stay
terminal (the fulfilled/revoked asymmetry); sweep detaches terminated
leaves by disconnecting their ``Owns`` edge and deleting the node.
"""

node Task {
    has tid: str;
    has state: str;
}

edge Owns: Task --> Task {}

node TaskRoot {}

glob ACTIVE: str = "active";
glob FULFILLED: str = "fulfilled";
glob REVOKED: str = "revoked";

"""Fresh tree root."""
def new_task_tree() -> TaskRoot {
    root ++> (r := TaskRoot());
    return r;
}

def _find_task(tree: TaskRoot, tid: str) -> Task | None {
    hits = [t for t in [tree -->][?:Task] if t.tid == tid];
    if len(hits) == 0 {
        return None;
    }
    return hits[0];
}

def _next_tid(tree: TaskRoot) -> str {
    all_t = [tree -->][?:Task];
    n = 1 + max([0] + [int(t.tid[1:]) for t in all_t]);
    return "t" + str(n);
}

"""Spawn a task under `parent_tid` (None for a root task); returns id."""
def spawn_task(tree: TaskRoot, parent_tid: str | None = None) -> str {
    tid = _next_tid(tree);
    root ++> (t := Task(tid=tid, state=ACTIVE));
    tree ++> t;
    if parent_tid is not None {
        p = _find_task(tree, parent_tid);
        if p is None {
            raise KeyError("unknown parent task");
        }
        p +>:Owns:+> t;
    }
    return tid;
}

"""Move an active task to fulfilled (terminal)."""
def complete(tree: TaskRoot, tid: str) -> str {
    t = _find_task(tree, tid);
    if t is None {
        raise KeyError("unknown task");
    }
    if t.state == ACTIVE {
        t.state = FULFILLED;
    }
    return t.state;
}

walker ActiveCollect {
    """Phase 1 of the cascade: gather active tasks once per node."""
    has claimed: dict[str, bool] = {};
    has to_revoke: list[str] = [];

    can step with Task entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        if here.state == ACTIVE {
            self.to_revoke.append(here.tid);
        }
        visit [->:Owns:->];
    }
}

"""Revoke `tid` and every active descendant; returns the count."""
def cancel(tree: TaskRoot, tid: str) -> int {
    t = _find_task(tree, tid);
    if t is None {
        raise KeyError("unknown task");
    }
    w = t spawn ActiveCollect();
    for x in w.to_revoke {
        node_ref = _find_task(tree, x);
        if node_ref is not None {
            node_ref.state = REVOKED;
        }
    }
    return len(w.to_revoke);
}

"""Detach terminated leaf tasks; returns how many were removed."""
def sweep(tree: TaskRoot) -> int {
    # Collect phase: find removable leaves without mutating mid-walk.
    doomed: list[Task] = [];
    for t in [tree -->][?:Task] {
        if t.state == ACTIVE {
            continue;
        }
        if len([t ->:Owns:->]) == 0 {
            doomed.append(t);
        }
    }
    removed = len(doomed);
    # Apply phase: disconnect from parent, then delete.
    for t in doomed {
        parents = [t ->:Owns:->];
        if len(parents) > 0 {
            t del ->:Owns:-> parents[0];
        } else {
            tree del --> t;
        }
        del t;
    }
    return removed;
}

"""Sorted ids of active direct children of `tid`."""
def active_children(tree: TaskRoot, tid: str) -> list[str] {
    t = _find_task(tree, tid);
    if t is None {
        raise KeyError("unknown task");
    }
    kids = [k for k in [t ->:Owns:->] if k.state == ACTIVE];
    return sorted(k.tid for k in kids);
}

walker ActiveSweep {
    """Gathers every active task below (and including) the start."""
    has claimed: dict[str, bool] = {};
    has actives: list[str] = [];

    can step with Task entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        if here.state == ACTIVE {
            self.actives.append(here.tid);
        }
        visit [->:Owns:->];
    }
}

"""Sorted ids of all active tasks below `tid` (inclusive)."""
def active_descendants(tree: TaskRoot, tid: str) -> list[str] {
    t = _find_task(tree, tid);
    if t is None {
        raise KeyError("unknown task");
    }
    w = t spawn ActiveSweep();
    return sorted(w.actives);
}
test "cancel cascade revokes active branch but spares fulfilled" {
    tree = new_task_tree();
    root_t = spawn_task(tree);
    a = spawn_task(tree, root_t);
    b = spawn_task(tree, a);
    c = spawn_task(tree, a);
    d = spawn_task(tree, b);
    assert complete(tree, c) == FULFILLED;
    assert cancel(tree, root_t) == 4;
    c_node = _find_task(tree, c);
    assert c_node is not None;
    assert c_node.state == FULFILLED;
    d_node = _find_task(tree, d);
    assert d_node is not None;
    assert d_node.state == REVOKED;
    assert active_descendants(tree, root_t) == [];
}

test "cancel mid-branch and sweep detached leaves" {
    tree = new_task_tree();
    r2 = spawn_task(tree);
    x = spawn_task(tree, r2);
    y = spawn_task(tree, x);
    z = spawn_task(tree, y);
    w = spawn_task(tree, x);
    assert complete(tree, z) == FULFILLED;
    assert cancel(tree, x) == 3;
    assert active_children(tree, x) == [];
    assert active_descendants(tree, y) == [];
    removed = sweep(tree);
    assert removed >= 1;
    while removed > 0 {
        removed = sweep(tree);
    }
    raised = False;
    try {
        cancel(tree, "ghost");
    } except KeyError {
        raised = True;
    }
    assert raised;
    cancel(tree, r2);
    for t in [tree -->][?:Task] {
        assert t.state != ACTIVE;
    }
}