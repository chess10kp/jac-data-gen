"""Task dependency queue with graph cycle detection.

Provenance: lucianfialho/effect-gates#58
"""

node Task {
    has tid: str;
    has done: bool = False;
}

edge Depends {}

walker TopoCycleProbe {
    has cyclic: bool = False;
    has path_set: dict[str, bool] = {};
    has claimed: dict[str, bool] = {};

    can dfs with Task entry {
        print(["topo_cycle", here.tid]);
        if here.tid in self.path_set {
            self.cyclic = True;
            disengage;
        }
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        self.path_set[here.tid] = True;
        deps: list[Task] = [here ->:Depends:->][?:Task];
        if deps {
            visit deps;
        }
        self.path_set[here.tid] = False;
        if len(deps) == 0 {
            disengage;
        }
    }
}

obj TaskQueue {
    has anchor: Task;

    def init {
        self.anchor = Task(tid="__anchor__");
        root ++> self.anchor;
    }
}

def make_queue -> TaskQueue {
    return TaskQueue();
}

def find_task_under(anchor: Task, tid: str) -> Task | None {
    if anchor.tid == tid {
        return anchor;
    }
    kids: list[Task] = [anchor ->][?:Task];
    for ch in kids {
        hit = find_task_under(ch, tid);
        if hit != None {
            return hit;
        }
    }
    return None;
}

def list_tasks(q: TaskQueue) -> list[str] {
    out: list[str] = [];
    kids: list[Task] = [q.anchor ->][?:Task];
    for t in kids {
        out.append(t.tid);
    }
    return sorted(out);
}

def has_direct_dep_dupes(deps: list[str]) -> bool {
    seen: dict[str, bool] = {};
    for d in deps {
        if d in seen {
            return True;
        }
        seen[d] = True;
    }
    return False;
}

def all_deps_done(t: Task) -> bool {
    deps: list[Task] = [t ->:Depends:->][?:Task];
    for d in deps {
        if not d.done {
            return False;
        }
    }
    return True;
}

def rollback_tentative(new_nd: Task) {
    parents: list[Task] = [<-:Depends:-][?:Task];
    for p in parents {
        del p +>:Depends:+> new_nd;
    }
    deps: list[Task] = [new_nd ->:Depends:->][?:Task];
    for d in deps {
        del new_nd +>:Depends:+> d;
    }
    anchor_kids: list[Task] = [root ->][?:Task];
    for a in anchor_kids {
        kids: list[Task] = [a ->][?:Task];
        for k in kids {
            if k.tid == new_nd.tid {
                del a ++> k;
            }
        }
    }
}

def add_task(q: TaskQueue, tid: str, deps: list[str] | None = None) -> bool {
    if deps == None {
        deps = [];
    }
    if find_task_under(q.anchor, tid) != None {
        return False;
    }
    if has_direct_dep_dupes(deps) {
        return False;
    }
    new_nd = Task(tid=tid);
    q.anchor ++> new_nd;
    for d in deps {
        dep_nd = find_task_under(q.anchor, d);
        if dep_nd == None {
            dep_nd = Task(tid=d);
            q.anchor ++> dep_nd;
        }
        new_nd +>:Depends:+> dep_nd;
    }
    w = new_nd spawn TopoCycleProbe(path_set={}, claimed={}, cyclic=False);
    if w.cyclic {
        rollback_tentative(new_nd);
        return False;
    }
    return True;
}

def get_ready(q: TaskQueue) -> list[str] {
    out: list[str] = [];
    kids: list[Task] = [q.anchor ->][?:Task];
    for t in kids {
        if not t.done and all_deps_done(t) {
            out.append(t.tid);
        }
    }
    return sorted(out);
}

def complete_task(q: TaskQueue, tid: str) -> bool {
    nd = find_task_under(q.anchor, tid);
    if nd == None {
        return False;
    }
    nd.done = True;
    return True;
}

def run_all(q: TaskQueue) -> list[str] {
    order: list[str] = [];
    while True {
        ready = get_ready(q);
        if len(ready) == 0 {
            break;
        }
        for tid in ready {
            complete_task(q, tid);
            order.append(tid);
        }
    }
    return order;
}

def pending_tasks(q: TaskQueue) -> list[str] {
    out: list[str] = [];
    kids: list[Task] = [q.anchor ->][?:Task];
    for t in kids {
        if not t.done {
            out.append(t.tid);
        }
    }
    return sorted(out);
}
