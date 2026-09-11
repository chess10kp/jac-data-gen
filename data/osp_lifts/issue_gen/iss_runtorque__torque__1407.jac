"""runtorque/torque#1407 — Completion-blocker query excludes auto-expirable engineer messages."""

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
