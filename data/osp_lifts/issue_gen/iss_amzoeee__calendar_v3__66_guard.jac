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

test "create and depth" {
    root_node = Task(tid="root", title="root");
    a = create_task(root_node, "a", "A");
    b = create_task(root_node, "b", "B", "a");
    c = create_task(root_node, "c", "C", "b");
    assert depth_of(root_node, "a") == 0;
    assert depth_of(root_node, "b") == 1;
    assert depth_of(root_node, "c") == 2;
    assert depth_of(root_node, "zz") == -1;
}

test "unknown parent tolerated as root" {
    root_node = Task(tid="root", title="root");
    x = create_task(root_node, "x", "X", "nope");
    assert depth_of(root_node, "x") == 0;
    assert len(subtree_ids(root_node, "x")) == 1;
}

test "can_indent respects max depth" {
    root_node = Task(tid="root", title="root");
    a = create_task(root_node, "a", "A");
    b = create_task(root_node, "b", "B", "a");
    c = create_task(root_node, "c", "C", "b");
    d = create_task(root_node, "d", "D", "c");
    assert can_indent(root_node, "a") == True;
    assert can_indent(root_node, "c") == True;
    assert can_indent(root_node, "d") == False;
}

test "subtree closure multiset and order independence" {
    root_node = Task(tid="root", title="root");
    a = create_task(root_node, "a", "A");
    b = create_task(root_node, "b", "B", "a");
    c = create_task(root_node, "c", "C", "b");
    d = create_task(root_node, "d", "D", "a");
    got = subtree_ids(root_node, "a");
    assert got == ["a", "b", "c", "d"];
    assert subtree_ids(root_node, "missing") == [];
}

test "complete cascade marks descendants once" {
    root_node = Task(tid="root", title="root");
    a = create_task(root_node, "a", "A");
    b = create_task(root_node, "b", "B", "a");
    c = create_task(root_node, "c", "C", "b");
    marked = complete_cascade(root_node, "a");
    assert marked == ["a", "b", "c"];
    assert c.done == True;
    assert complete_cascade(root_node, "zz") == [];
}

test "can_move walker" {
    root_node = Task(tid="root", title="root");
    a = create_task(root_node, "a", "A");
    b = create_task(root_node, "b", "B", "a");
    c = create_task(root_node, "c", "C", "b");
    d = create_task(root_node, "d", "D", "c");
    assert can_move(root_node, "a") == True;
    assert can_move(root_node, "d") == False;
    assert can_move(root_node, "zz") == False;
}
