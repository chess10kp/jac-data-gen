"""Task dependencies and derived blocking.

KaviiSuri/bb-plugin-tasks#1 lifted to OSP: tasks become TaskNode
archetypes; both adjacency dicts collapse into one typed Blocks edge
family walked forward for dependents and backward for blockers. Linking
rejects self/duplicate/cycle transactionally -- cycle detection is a
downstream walker whose claim map tolerates resolved edges. Status
changes trigger a two-phase dependent sweep that refreshes the derived
blocked badge; badges are never a workflow status.
"""
node TaskNode {
    has task_id: str;
    has status: str = "todo";
    has blocked_badge: bool = False;
}
edge Blocks {}

"""Board handle: id resolution through this lookup map is domain API."""
obj Board {
    has tasks: dict[str, TaskNode];

    def resolve(task_id: str) -> TaskNode | None {
        return self.tasks.get(task_id);
    }
}

def build_board(ids: list[str]) -> Board {
    b = Board(tasks={});
    for tid in ids {
        t = TaskNode(task_id=tid);
        root ++> t;
        b.tasks[tid] = t;
    }
    return b;
}

def add_task(b: Board, task_id: str, status: str = "todo") {
    t = TaskNode(task_id=task_id, status=status);
    root ++> t;
    b.tasks[task_id] = t;
    _refresh_badge(t);
}


def _is_terminal(t: TaskNode) -> bool {
    return t.status == "done" or t.status == "canceled";
}

"""Recomputes the DERIVED badge; returns the sorted unresolved blockers."""
def _refresh_badge(t: TaskNode) -> list[str] {
    active: list[str] = [];
    blks: list[TaskNode] = [t <-:Blocks:<-];
    for blk in blks {
        if not _is_terminal(blk) {
            active.append(blk.task_id);
        }
    }
    t.blocked_badge = (not _is_terminal(t)) and len(active) > 0;
    return sorted(active);
}

"""Downstream DFS over Blocks edges; once-only claim map cycle policy.

Cycle detection deliberately includes edges into terminal tasks --
resolved edges still close cycles.
"""
walker DownstreamCheck {
    has claimed: dict[str, bool];
    has target: str;
    has found: bool = False;

    can step with TaskNode entry {
        if here.task_id == self.target {
            self.found = True;
            disengage;
        }
        if here.task_id in self.claimed {
            skip;
        }
        self.claimed[here.task_id] = True;
        visit [->:Blocks:->];
    }
}

def link(b: Board, blocker: str, dependent: str) {
    bt = b.resolve(blocker);
    dt = b.resolve(dependent);
    if bt is None or dt is None {
        raise KeyError("unknown task");
    }
    if blocker == dependent {
        raise ValueError("self link");
    }
    dup = False;
    holders: list[TaskNode] = [dt <-:Blocks:<-];
    for h in holders {
        if h.task_id == blocker {
            dup = True;
        }
    }
    if dup {
        raise ValueError("duplicate edge");
    }
    w = dt spawn DownstreamCheck(claimed={}, target=blocker);
    if w.found {
        raise ValueError("dependency cycle");
    }
    # Transactional apply happens only after every check passed.
    bt +>:Blocks:+> dt;
    _refresh_badge(dt);
}

"""Invalidation sweep: recompute direct dependents' badges."""
def _sweep_dependents(t: TaskNode) -> dict {
    touched: dict = {};
    deps: list[TaskNode] = [t ->:Blocks:->];
    for d in deps {
        touched[d.task_id] = _refresh_badge(d);
    }
    return touched;
}

def complete(b: Board, task_id: str) -> dict {
    t = b.resolve(task_id);
    if t is None {
        raise KeyError("unknown task");
    }
    t.status = "done";
    _refresh_badge(t);
    return _sweep_dependents(t);
}

def cancel(b: Board, task_id: str) -> dict {
    t = b.resolve(task_id);
    if t is None {
        raise KeyError("unknown task");
    }
    t.status = "canceled";
    _refresh_badge(t);
    return _sweep_dependents(t);
}

def reopen(b: Board, task_id: str) -> dict {
    t = b.resolve(task_id);
    if t is None {
        raise KeyError("unknown task");
    }
    t.status = "todo";
    _refresh_badge(t);
    return _sweep_dependents(t);
}

def is_blocked(b: Board, task_id: str) -> bool {
    t = b.resolve(task_id);
    if t is None {
        return False;
    }
    return t.blocked_badge;
}

def unresolved_blocker_count(b: Board, task_id: str) -> int {
    t = b.resolve(task_id);
    if t is None {
        return 0;
    }
    count = 0;
    blks: list[TaskNode] = [t <-:Blocks:<-];
    for blk in blks {
        if not _is_terminal(blk) {
            count += 1;
        }
    }
    return count;
}

def blocked_tasks(b: Board) -> list[str] {
    out: list[str] = [];
    for k in b.tasks.keys() {
        t = b.resolve(k);
        if t is not None and t.blocked_badge {
            out.append(k);
        }
    }
    return sorted(out);
}
