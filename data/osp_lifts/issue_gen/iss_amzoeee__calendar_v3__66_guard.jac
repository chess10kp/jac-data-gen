# Lifting amzoeee/calendar_v3#66 — allow subtasks deeper than one level.
# Hand-rolled recursive CTE / parent-pointer machinery -> idiomatic Jac OSP.

node Task {
    has tid: str;
    has title: str;
    has done: bool = False;
    has depth: int = 0;
}

edge PARENT {}

const MAX_TASK_DEPTH = 3;

def all_tasks(graph_root: Task) -> list[Task] {
    # BFS over untyped root edges collecting every Task node
    out: list[Task] = [];
    claimed: dict[str, bool] = {};
    queue: list[Task] = [graph_root];
    while len(queue) > 0 {
        cur = queue.pop(0);
        out.append(cur);
        for nxt in [cur ->] {
            if nxt isa Task {
                t = nxt as Task;
                if t.tid not in claimed {
                    claimed[t.tid] = True;
                    queue.append(t);
                }
            }
        }
    }
    return out;
}

def find_task(graph_root: Task, tid: str) -> Task | None {
    ts: list[Task] = all_tasks(graph_root);
    for t in ts {
        if t.tid == tid {
            return t;
        }
    }
    return None;
}

def _task_depth(here: Task) -> int {
    # depth = chain length to root via PARENT edges
    d: int = 0;
    cur: Task | None = here;
    while cur is not None {
        ups: list[Task] = [cur ->:PARENT:->];
        if len(ups) == 0 {
            cur = None;
        } else {
            cur = ups[0];
            d += 1;
        }
    }
    return d;
}

def create_task(graph_root: Task, tid: str, title: str, parent_tid: str | None = None) -> Task {
    # unknown parent id is tolerated as a root-level task
    nd = Task(tid=tid, title=title);
    par: Task | None = None;
    if parent_tid is not None {
        par = find_task(graph_root, parent_tid);
    }
    if par is None {
        graph_root ++> nd;
        nd.depth = 0;
    } else {
        par +>:PARENT:+> nd;
        nd.depth = _task_depth(nd);
    }
    return nd;
}

def depth_of(graph_root: Task, tid: str) -> int {
    t: Task | None = find_task(graph_root, tid);
    if t is None {
        return -1;
    }
    return t.depth;
}

def can_indent(graph_root: Task, tid: str) -> bool {
    d: int = depth_of(graph_root, tid);
    return d >= 0 and d < MAX_TASK_DEPTH;
}

def subtree_ids(graph_root: Task, tid: str) -> list[str] {
    # BFS closure over PARENT children, unknown id -> []
    start: Task | None = find_task(graph_root, tid);
    out: list[str] = [];
    if start is None {
        return out;
    }
    claimed: dict[str, bool] = {};
    queue: list[Task] = [start];
    while len(queue) > 0 {
        cur = queue.pop(0);
        if cur.tid in claimed {
            continue;
        }
        claimed[cur.tid] = True;
        out.append(cur.tid);
        kids: list[Task] = [cur ->:PARENT:->];
        kids.sort(key=lambda k: k.tid);
        for k in kids {
            queue.append(k);
        }
    }
    out.sort();
    return out;
}

walker CompleteCascade {
    has claimed: dict[str, bool] = {};
    has marked: list[str] = [];

    can step with Task entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        here.done = True;
        self.marked.append(here.tid);
        kids: list[Task] = [here ->:PARENT:->];
        kids.sort(key=lambda k: k.tid);
        visit kids;
    }
}

def complete_cascade(graph_root: Task, tid: str) -> list[str] {
    start: Task | None = find_task(graph_root, tid);
    if start is None {
        return [];
    }
    wk = start spawn CompleteCascade(claimed={}, marked=[]);
    return sorted(wk.marked);
}

walker MoveValidator {
    has target_tid: str = "";
    has ok: bool = False;

    can step with Task entry {
        if here.tid == self.target_tid {
            self.ok = here.depth < MAX_TASK_DEPTH;
            disengage;
        }
        kids: list[Task] = [here ->:PARENT:->];
        visit kids else {
            disengage;
        }
    }
}

def can_move(graph_root: Task, tid: str) -> bool {
    wk = graph_root spawn MoveValidator(target_tid=tid, ok=False);
    return wk.ok;
}

test "create_and_depth" {
    r = Task(tid="r", title="root");
    a = create_task(r, "a", "A");
    b = create_task(r, "b", "B", parent_tid="a");
    c = create_task(r, "c", "C", parent_tid="b");
    d = create_task(r, "d", "D", parent_tid="zz");
    assert depth_of(r, "a") == 0;
    assert depth_of(r, "b") == 1;
    assert depth_of(r, "c") == 2;
    assert depth_of(r, "d") == 0;
    assert depth_of(r, "nope") == -1;
}

test "can_indent_bound" {
    r = Task(tid="r", title="root");
    create_task(r, "a", "A");
    create_task(r, "b", "B", parent_tid="a");
    create_task(r, "c", "C", parent_tid="b");
    create_task(r, "d", "D", parent_tid="c");
    assert can_indent(r, "a") == True;
    assert can_indent(r, "c") == True;
    assert can_indent(r, "d") == False;
    assert can_move(r, "d") == False;
    assert can_move(r, "c") == True;
}

test "subtree_closure" {
    r = Task(tid="r", title="root");
    create_task(r, "a", "A");
    create_task(r, "b", "B", parent_tid="a");
    create_task(r, "c", "C", parent_tid="a");
    create_task(r, "d", "D", parent_tid="b");
    assert subtree_ids(r, "a") == ["a", "b", "c", "d"];
    assert subtree_ids(r, "b") == ["b", "d"];
    assert subtree_ids(r, "zz") == [];
}

test "cascade_marks_descendants" {
    r = Task(tid="r", title="root");
    create_task(r, "a", "A");
    create_task(r, "b", "B", parent_tid="a");
    create_task(r, "c", "C", parent_tid="b");
    create_task(r, "x", "X");
    marked = complete_cascade(r, "a");
    assert marked == ["a", "b", "c"];
    t = find_task(r, "c");
    assert t is not None and t.done == True;
    tx = find_task(r, "x");
    assert tx is not None and tx.done == False;
}

test "complete_cascade_unknown" {
    r = Task(tid="r", title="root");
    create_task(r, "a", "A");
    assert complete_cascade(r, "zz") == [];
    assert len(all_tasks(r)) == 2;
}

test "find_task" {
    r = Task(tid="r", title="root");
    create_task(r, "a", "A");
    assert find_task(r, "a") is not None;
    assert find_task(r, "zz") is None;
}
