"""Hierarchical queue close/open admission with cascade semantics.

volcano-sh/volcano#5351 lifted to OSP: queues become QueueNode archetypes,
parent pointers and the children adjacency map become typed Subqueue
edges. Close is two-phase -- a CascadeCollect walker with a once-only
claim map gathers the subtree, the facade flips states outside the walk.
Open climbs ancestors via an ascent walker and is rejected when any of
them is Closed; foreground deletion demands a fully-closed subtree before
disconnect + unregister. Claim maps are the cycle policy throughout.
"""
class AdmissionError(ValueError) {}

node QueueNode {
    has name: str;
    has state: str = "Open";
}
edge Subqueue {}

"""Tree handle: id resolution through this lookup map is domain API."""
obj Hierarchy {
    has queues: dict[str, QueueNode];

    def resolve(name: str) -> QueueNode | None {
        return self.queues.get(name);
    }
}

def build_tree(names: list[str], links: list[tuple[str, str]]) -> Hierarchy {
    h = Hierarchy(queues={});
    for n in names {
        q = QueueNode(name=n);
        root ++> q;
        h.queues[n] = q;
    }
    for lk in links {
        p = h.resolve(lk[0]);
        c = h.resolve(lk[1]);
        if p is not None and c is not None {
            p +>:Subqueue:+> c;
        }
    }
    return h;
}

def add_queue(h: Hierarchy, name: str, parent: str | None = None) {
    if parent is not None and h.resolve(parent) is None {
        raise KeyError("unknown parent queue");
    }
    q = QueueNode(name=name);
    root ++> q;
    h.queues[name] = q;
    if parent is not None {
        p = h.resolve(parent);
        if p is not None {
            p +>:Subqueue:+> q;
        }
    }
}

"""Gathers the subtree over Subqueue edges; once-only claim guard."""
walker CascadeCollect {
    has claimed: dict[str, bool];
    has found: list[QueueNode] = [];

    can step with QueueNode entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.found.append(here);
        visit [->:Subqueue:->];
    }
}

walker AncestorStates {
    has visited: dict[str, bool];
    has closed_ancestor: bool = False;

    can step with QueueNode entry {
        if here.name in self.visited {
            skip;  # tolerate corrupt cycles
        }
        self.visited[here.name] = True;
        parents: list[QueueNode] = [here <-:Subqueue:<-];
        if len(parents) == 0 {
            disengage;
        }
        par = parents[0];
        if par.state == "Closed" {
            self.closed_ancestor = True;
            disengage;
        }
        visit [par];
    }
}

def open_queue(h: Hierarchy, name: str) -> bool {
    q = h.resolve(name);
    if q is None {
        raise KeyError("unknown queue");
    }
    w = q spawn AncestorStates(visited={});
    if w.closed_ancestor {
        raise AdmissionError("parent queue is closed");
    }
    q.state = "Open";
    return True;
}

"""Closing a parent synchronously closes ALL descendants (two-phase)."""
def close_queue(h: Hierarchy, name: str) -> list[str] {
    start = h.resolve(name);
    if start is None {
        raise KeyError("unknown queue");
    }
    w = start spawn CascadeCollect(claimed={});
    flipped: list[str] = [];
    for qn in w.found {  # apply outside the walk
        if qn.state != "Closed" {
            qn.state = "Closed";
            flipped.append(qn.name);
        }
    }
    return sorted(flipped);
}

def _subtree_names(h: Hierarchy, name: str) -> list[str] | None {
    start = h.resolve(name);
    if start is None {
        return None;
    }
    w = start spawn CascadeCollect(claimed={});
    return [n.name for n in w.found];
}

def delete_queue_foreground(h: Hierarchy, name: str) -> list[str] {
    subtree = _subtree_names(h, name);
    if subtree is None {
        raise KeyError("unknown queue");
    }
    still_open: list[str] = [];
    for qn in subtree {
        nd = h.resolve(qn);
        if nd is not None and nd.state == "Open" {
            still_open.append(qn);
        }
    }
    if len(still_open) > 0 {
        # message carries the offending ids, like the source
        raise AdmissionError("subtree not closed: {}".format(still_open));
    }
    # Phase 2: detach from parent, then unregister the whole subtree.
    start2 = h.resolve(name);
    if start2 is None {
        raise KeyError("unknown queue");
    }
    parents: list[QueueNode] = [start2 <-:Subqueue:<-];
    if len(parents) > 0 {
        par = parents[0];
        # sever the attachment so the tree no longer reaches the subtree
        par del ->:Subqueue:-> start2;
    }
    removed: list[str] = sorted(subtree);
    for qn in subtree {
        h.queues.pop(qn, None);
    }
    return removed;
}

def is_open(h: Hierarchy, name: str) -> bool {
    q = h.resolve(name);
    if q is None {
        raise KeyError("unknown queue");
    }
    return q.state == "Open";
}

def descendants(h: Hierarchy, name: str) -> list[str] {
    all_names = _subtree_names(h, name);
    out: list[str] = [];
    for n in all_names {
        if n != name {
            out.append(n);
        }
    }
    return sorted(out);
}
test "close cascade reaches the whole subtree once" {
    h = build_tree(["root", "eng", "sci", "ml", "infra", "physics"], [("root", "eng"), ("root", "sci"), ("eng", "ml"), ("eng", "infra"), ("sci", "physics")]);
    assert close_queue(h, "root") == ["eng", "infra", "ml", "physics", "root", "sci"];
    assert close_queue(h, "root") == [];
    assert not is_open(h, "physics");
}

test "open rejected under closed ancestor" {
    h = build_tree(["root", "eng", "ml"], [("root", "eng"), ("eng", "ml")]);
    close_queue(h, "eng");
    try {
        open_queue(h, "ml");
        assert False, "expected admission error";
    } except ValueError { assert True; }
    assert open_queue(h, "root");   # root has no ancestors
    assert open_queue(h, "eng");
    assert open_queue(h, "ml");
}

test "foreground deletion requires fully-closed subtree" {
    h = build_tree(["r", "a", "b"], [("r", "a"), ("a", "b")]);
    try {
        delete_queue_foreground(h, "r");
        assert False, "expected open subtree rejection";
    } except AdmissionError as e {
        # the message names every still-open id in the doomed subtree
        assert str(e) == "subtree not closed: ['r', 'a', 'b']", str(e);
    }
    close_queue(h, "a");  # cascades to b
    try {
        delete_queue_foreground(h, "r");
        assert False;
    } except AdmissionError as e {
        assert str(e) == "subtree not closed: ['r']", str(e);
    }
    close_queue(h, "r");
    removed = delete_queue_foreground(h, "a");
    assert removed == ["a", "b"];
    assert sorted(descendants(h, "r")) == [];
    try {
        is_open(h, "b");
        assert False;
    } except KeyError { assert True; }
}

test "corrupt parent cycle terminates" {
    h = build_tree(["x", "y"], []);
    xn = h.resolve("x");
    yn = h.resolve("y");
    if xn is None or yn is None {
        assert False, "expected nodes x and y";
        return;
    }
    xn +>:Subqueue:+> yn;
    yn +>:Subqueue:+> xn;
    sn = _subtree_names(h, "x");
    if sn is None {
        assert False, "expected subtree for x";
        return;
    }
    assert sorted(sn) == ["x", "y"];
    w = xn spawn AncestorStates(visited={});
    assert not w.closed_ancestor;
}