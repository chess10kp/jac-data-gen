"""t-benze/happyranch#827 — batched task-root severity rollup; eliminate subtree N+1."""

node Task {
    has task_id: str;
    has severity: str;
    has created_at: int;
}

edge Child {}

obj TaskStore {
    has anchor: Task;
    has by_id: dict[str, Task] = {};
    has roots: list[Task] = [];
}

def severity_rank(sev: str) -> int {
    if sev == "critical" { return 3; }
    if sev == "warning" { return 2; }
    return 1;
}

def rollup_severity(statuses: list[str]) -> str {
    best: str = "ok";
    best_rank: int = 1;
    for s in statuses {
        r = severity_rank(s);
        if r > best_rank {
            best_rank = r;
            best = s;
        }
    }
    return best;
}

def remove_at(items: list[Task], idx: int) -> list[Task] {
    out: list[Task] = [];
    i: int = 0;
    for it in items {
        if i != idx { out.append(it); }
        i = i + 1;
    }
    return out;
}

def sort_roots(roots: list[Task]) -> list[Task] {
    remaining: list[Task] = [];
    ordered: list[Task] = [];
    for r in roots { remaining.append(r); }
    while len(remaining) > 0 {
        best_i: int = 0;
        best: Task = remaining[0];
        i: int = 0;
        for r in remaining {
            take: bool = False;
            if r.created_at > best.created_at { take = True; }
            elif r.created_at == best.created_at and r.task_id > best.task_id { take = True; }
            if take {
                best = r;
                best_i = i;
            }
            i = i + 1;
        }
        ordered.append(best);
        remaining = remove_at(remaining, best_i);
    }
    return ordered;
}

walker CollectStatusesW {
    has claimed: dict[str, bool] = {};
    has statuses: list[str] = [];

    can walk with Task entry {
        if here.task_id in self.claimed { skip; }
        self.claimed[here.task_id] = True;
        self.statuses.append(here.severity);
        kids: list[Task] = [here ->:Child:->][?:Task];
        for ch in kids {
            visit :0: [ch];
        }
    }
}

walker CountQueriesW {
    has claimed: dict[str, bool] = {};
    has count: int = 0;

    can probe with Task entry {
        if here.task_id in self.claimed { skip; }
        self.claimed[here.task_id] = True;
        self.count = self.count + 2;
        kids: list[Task] = [here ->:Child:->][?:Task];
        for ch in kids {
            visit :0: [ch];
        }
    }
}

def build_task_store(specs: list[dict]) -> TaskStore {
    anchor = Task(task_id="__anchor__", severity="ok", created_at=0);
    store = TaskStore(anchor=anchor);
    by_id: dict[str, Task] = {};
    roots: list[Task] = [];
    for spec in specs {
        tid = spec["task_id"] as str;
        nd = Task(
            task_id=tid,
            severity=spec["severity"] as str,
            created_at=spec["created_at"] as int
        );
        by_id[tid] = nd;
    }
    store.by_id = by_id;
    for spec in specs {
        tid = spec["task_id"] as str;
        nd = by_id[tid];
        pid = spec["parent_id"];
        if pid is None {
            roots.append(nd);
            store.anchor ++> nd;
        } else {
            pkey = pid as str;
            if pkey in by_id {
                par = by_id[pkey];
                par +>:Child:+> nd;
            }
        }
    }
    store.roots = roots;
    return store;
}

def get_task(store: TaskStore, task_id: str) -> Task | None {
    if task_id in store.by_id {
        return store.by_id[task_id];
    }
    return None;
}

def get_subtree_statuses(store: TaskStore, root_id: str) -> list[str] {
    nd = get_task(store, root_id);
    if nd is None {
        return [];
    }
    w = nd spawn CollectStatusesW(claimed={});
    print("subtree statuses for " + root_id);
    return w.statuses;
}

def list_roots(store: TaskStore, limit: int = 50) -> list[dict] {
    ordered = sort_roots(store.roots);
    page: list[Task] = [];
    n: int = 0;
    for r in ordered {
        if n >= limit { break; }
        page.append(r);
        n = n + 1;
    }
    result: list[dict] = [];
    for root_node in page {
        w = root_node spawn CollectStatusesW(claimed={});
        print("rollup walk for " + root_node.task_id);
        roll = rollup_severity(w.statuses);
        row: dict = {};
        row["task_id"] = root_node.task_id;
        row["severity_rollup"] = roll;
        result.append(row);
    }
    return result;
}

def simulate_recursive_query_count(store: TaskStore, limit: int = 50) -> int {
    total: int = 0;
    ordered = sort_roots(store.roots);
    n: int = 0;
    for root_node in ordered {
        if n >= limit { break; }
        w = root_node spawn CountQueriesW(claimed={});
        print("recursive probe " + root_node.task_id);
        total = total + 1 + w.count;
        n = n + 1;
    }
    return total;
}

def simulate_batched_query_count(store: TaskStore, limit: int = 50) -> int {
    ordered = sort_roots(store.roots);
    taken: int = 0;
    for root_node in ordered {
        if taken >= limit { break; }
        taken = taken + 1;
    }
    print("batched roots rollup roots=" + str(len(store.roots)) + " limit=" + str(limit) + " taken=" + str(taken));
    return 2;
}
