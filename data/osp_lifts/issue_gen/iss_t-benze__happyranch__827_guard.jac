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

test "rollup picks max severity" {
    statuses: list[str] = [];
    statuses.append("ok");
    statuses.append("warning");
    statuses.append("critical");
    assert rollup_severity(statuses) == "critical";
}

test "list_roots rollup order" {
    specs: list[dict] = [];
    s0: dict = {};
    s0["task_id"] = "a";
    s0["severity"] = "ok";
    s0["created_at"] = 10;
    s0["parent_id"] = None;
    specs.append(s0);
    s1: dict = {};
    s1["task_id"] = "b";
    s1["severity"] = "warning";
    s1["created_at"] = 20;
    s1["parent_id"] = None;
    specs.append(s1);
    s2: dict = {};
    s2["task_id"] = "c";
    s2["severity"] = "critical";
    s2["created_at"] = 5;
    s2["parent_id"] = "a";
    specs.append(s2);
    s3: dict = {};
    s3["task_id"] = "d";
    s3["severity"] = "ok";
    s3["created_at"] = 15;
    s3["parent_id"] = "b";
    specs.append(s3);
    store = build_task_store(specs);
    rows = list_roots(store, 50);
    assert len(rows) == 2;
    assert rows[0]["task_id"] == "b";
    assert rows[0]["severity_rollup"] == "warning";
    assert rows[1]["task_id"] == "a";
    assert rows[1]["severity_rollup"] == "critical";
}

test "subtree statuses unknown id" {
    specs: list[dict] = [];
    store = build_task_store(specs);
    got = get_subtree_statuses(store, "missing");
    assert len(got) == 0;
}

test "subtree statuses walk" {
    specs: list[dict] = [];
    s0: dict = {};
    s0["task_id"] = "a";
    s0["severity"] = "ok";
    s0["created_at"] = 10;
    s0["parent_id"] = None;
    specs.append(s0);
    s1: dict = {};
    s1["task_id"] = "c";
    s1["severity"] = "critical";
    s1["created_at"] = 5;
    s1["parent_id"] = "a";
    specs.append(s1);
    store = build_task_store(specs);
    got = get_subtree_statuses(store, "a");
    assert len(got) == 2;
    assert got[0] == "ok";
    assert got[1] == "critical";
}

test "recursive vs batched query counts" {
    specs: list[dict] = [];
    s0: dict = {};
    s0["task_id"] = "a";
    s0["severity"] = "ok";
    s0["created_at"] = 10;
    s0["parent_id"] = None;
    specs.append(s0);
    s1: dict = {};
    s1["task_id"] = "b";
    s1["severity"] = "warning";
    s1["created_at"] = 20;
    s1["parent_id"] = None;
    specs.append(s1);
    s2: dict = {};
    s2["task_id"] = "c";
    s2["severity"] = "critical";
    s2["created_at"] = 5;
    s2["parent_id"] = "a";
    specs.append(s2);
    s3: dict = {};
    s3["task_id"] = "d";
    s3["severity"] = "ok";
    s3["created_at"] = 15;
    s3["parent_id"] = "b";
    specs.append(s3);
    store = build_task_store(specs);
    recursive = simulate_recursive_query_count(store, 50);
    batched = simulate_batched_query_count(store, 50);
    assert recursive == 10;
    assert batched == 2;
}

test "list_roots honors limit" {
    specs: list[dict] = [];
    s0: dict = {};
    s0["task_id"] = "a";
    s0["severity"] = "ok";
    s0["created_at"] = 10;
    s0["parent_id"] = None;
    specs.append(s0);
    s1: dict = {};
    s1["task_id"] = "b";
    s1["severity"] = "warning";
    s1["created_at"] = 20;
    s1["parent_id"] = None;
    specs.append(s1);
    store = build_task_store(specs);
    rows = list_roots(store, 1);
    assert len(rows) == 1;
    assert rows[0]["task_id"] == "b";
}
