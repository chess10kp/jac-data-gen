"""Guard: runtorque/torque#1407."""

obj BoardStore {
    has tasks: dict[str, Task] = {};
}

node Task {
    has tid: str;
    has status: str;
    has labels: list[str] = [];
}

edge ChildOf {}

walker OpenDescWalk {
    has claimed: dict[str, bool] = {};
    has open_ids: list[str] = [];
    has origin: str = "";

    can step with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        if here.tid != self.origin and here.status != "Done" {
            self.open_ids.append(here.tid);
        }
        visit [->:ChildOf:->] else { disengage; };
    }
}

def load_board(
    tasks: list[tuple[str, str, list[str]]],
    child_edges: list[tuple[str, str]],
) -> BoardStore {
    g = BoardStore();
    for (tid, status, labels) in tasks {
        if tid not in g.tasks {
            nd = Task(tid=tid, status=status, labels=labels);
            root ++> nd;
            g.tasks[tid] = nd;
        }
    }
    for (parent, child) in child_edges {
        p = g.tasks.get(parent, None);
        c = g.tasks.get(child, None);
        if p is not None and c is not None { p +>:ChildOf:+> c; }
    }
    return g;
}

def task_is_engineer_message_followup(store: BoardStore, task_id: str) -> bool {
    nd = store.tasks.get(task_id, None);
    if nd is None { return False; }
    return "torque:engineer-message" in nd.labels;
}

def task_open_descendants(store: BoardStore, task_id: str) -> list[str] {
    anchor = store.tasks.get(task_id, None);
    if anchor is None { return []; }
    w = anchor spawn OpenDescWalk(claimed={}, open_ids=[], origin=task_id);
    return sorted(w.open_ids);
}

def task_has_unresolved_descendants(store: BoardStore, task_id: str) -> bool {
    return len(task_open_descendants(store, task_id)) > 0;
}

def task_has_unresolved_completion_blockers(store: BoardStore, task_id: str) -> bool {
    for tid in task_open_descendants(store, task_id) {
        if not task_is_engineer_message_followup(store, tid) {
            return True;
        }
    }
    return False;
}

test "1588 engineer message blocks descendants not completion" {
    g = load_board(
        [
            ("root", "In Progress", ["torque:legacy-root"]),
            ("review", "Done", ["torque:ship-review"]),
            ("msg", "Backlog", ["torque:derived", "torque:engineer-message"]),
        ],
        [("root", "review"), ("root", "msg")],
    );
    assert task_open_descendants(g, "root") == ["msg"];
    assert task_has_unresolved_descendants(g, "root") is True;
    assert task_is_engineer_message_followup(g, "msg") is True;
    assert task_has_unresolved_completion_blockers(g, "root") is False;
}

test "1587 control no open descendants" {
    g = load_board(
        [("root", "In Progress", []), ("review", "Done", [])],
        [("root", "review")],
    );
    assert task_open_descendants(g, "root") == [];
    assert task_has_unresolved_descendants(g, "root") is False;
    assert task_has_unresolved_completion_blockers(g, "root") is False;
}

test "human ask still blocks completion" {
    g = load_board(
        [("root", "In Progress", []), ("work", "Backlog", ["torque:human"])],
        [("root", "work")],
    );
    assert task_has_unresolved_descendants(g, "root") is True;
    assert task_has_unresolved_completion_blockers(g, "root") is True;
}

test "diamond adversarial revisit before deep first-visit" {
    g = load_board(
        [
            ("hub", "Done", []),
            ("left", "Done", []),
            ("right", "Done", []),
            ("leaf", "Backlog", []),
        ],
        [("right", "leaf"), ("hub", "left"), ("left", "leaf"), ("hub", "right")],
    );
    assert task_open_descendants(g, "hub") == ["leaf"];
}

test "cycle terminates once per task" {
    g = load_board(
        [("a", "Done", []), ("b", "Done", []), ("c", "Backlog", [])],
        [("a", "b"), ("b", "c"), ("c", "a")],
    );
    assert task_open_descendants(g, "a") == ["c"];
}

test "unknown item tolerant" {
    g = load_board([("solo", "Done", [])], []);
    assert task_open_descendants(g, "missing") == [];
    assert task_has_unresolved_descendants(g, "missing") is False;
    assert task_has_unresolved_completion_blockers(g, "missing") is False;
    assert task_is_engineer_message_followup(g, "missing") is False;
}
