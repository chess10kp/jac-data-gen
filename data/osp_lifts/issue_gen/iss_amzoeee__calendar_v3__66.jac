"""Tasks: allow subtasks deeper than one level — amzoeee/calendar_v3#66."""

glob MAX_TASK_DEPTH: int = 2;

node Task {
    has id: str;
    has depth: int = 0;
    has done: bool = False;
}

edge Subtask {}

walker FindTask {
    has sought: str;
    has hit: Task | None = None;
    has claimed: dict[str, bool] = {};

    can seek with Task entry {
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        if here.id == self.sought {
            self.hit = here;
            print(here.id);
            disengage;
        }
        kids: list[Task] = [here ->:Subtask:->][?:Task];
        for kid in kids {
            visit :0: [kid];
        }
    }
}

walker SubtreeCollect {
    has found: list[str] = [];
    has claimed: dict[str, bool] = {};

    can gather with Task entry {
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        self.found.append(here.id);
        print(here.id);
        kids: list[Task] = [here ->:Subtask:->][?:Task];
        for kid in kids {
            visit :0: [kid];
        }
    }
}

def find_task_node(graph_root: Task, task_id: str) -> Task | None {
    w = graph_root spawn FindTask(sought=task_id, claimed={});
    return w.hit;
}

def max_task_depth -> int {
    return MAX_TASK_DEPTH;
}

def can_nest_child(parent_depth: int) -> bool {
    return parent_depth < MAX_TASK_DEPTH;
}

def validate_depth(depth: int) -> bool {
    return depth <= MAX_TASK_DEPTH;
}

def build_task_graph(rows: list) -> Task {
    store: dict[str, Task] = {};
    anchor = Task(id="__root__", depth=-1);
    root ++> anchor;
    for row in rows {
        tid = row["id"];
        tdepth = row["depth"];
        nd = Task(id=tid, depth=tdepth);
        store[tid] = nd;
    }
    for row in rows {
        tid = row["id"];
        pid = row["parentId"];
        child = store[tid] as Task;
        if pid is not None {
            parent = store[pid] as Task;
            parent +>:Subtask:+> child;
        } else {
            anchor +>:Subtask:+> child;
        }
    }
    return anchor;
}

def collect_subtree_ids(graph_root: Task, task_id: str) -> list[str] {
    target = find_task_node(graph_root, task_id);
    if target is None {
        return [];
    }
    w = target spawn SubtreeCollect(claimed={});
    out: list[str] = [];
    for x in w.found {
        out.append(x);
    }
    return sorted(out);
}

def cascade_complete(graph_root: Task, task_id: str) -> list[str] {
    ids = collect_subtree_ids(graph_root, task_id);
    for tid in ids {
        nd = find_task_node(graph_root, tid);
        if nd is not None {
            nd.done = True;
        }
    }
    return ids;
}
