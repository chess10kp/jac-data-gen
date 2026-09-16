"""
t-benze/happyranch#827 - batched subtree severity rollup for task roots.
"""

node TaskAnchor {
    has label: str = "happyranch_tasks";
}

node Task {
    has tid: str;
    has status: str;
    has created_at: int = 0;
    has sort_id: int = 0;
}

edge RootLink {}
edge Child {}

glob SEVERITY_RANK: dict[str, int] = {
    "critical": 4,
    "error": 3,
    "warning": 2,
    "ok": 1,
};

def sort_tasks_desc(items: list[Task]) -> list[Task] {
    n = len(items);
    i = 0;
    while i < n {
        j = i + 1;
        while j < n {
            a = items[i] as Task;
            b = items[j] as Task;
            swap = False;
            if a.created_at < b.created_at {
                swap = True;
            } elif a.created_at == b.created_at and a.sort_id < b.sort_id {
                swap = True;
            }
            if swap {
                items[i] = b;
                items[j] = a;
            }
            j += 1;
        }
        i += 1;
    }
    return items;
}

def attach_tasks(anchor: TaskAnchor, rows: list[dict]) {
    by_id: dict[str, Task] = {};
    for row in rows {
        nd = Task(
            tid=row["id"] as str,
            status=row["status"] as str,
            created_at=row["created_at"] as int,
            sort_id=row["sort_id"] as int,
        );
        by_id[row["id"] as str] = nd;
    }
    for row in rows {
        pid = row["parent_id"] as str;
        if pid == "" {
            rt = by_id[row["id"] as str] as Task;
            anchor +>:RootLink:+> rt;
        }
    }
    for row in rows {
        pid = row["parent_id"] as str;
        if pid != "" {
            p = by_id[pid] as Task;
            c = by_id[row["id"] as str] as Task;
            p +>:Child:+> c;
        }
        extras: list[str] = [];
        if "extra_parents" in row {
            extras = row["extra_parents"] as list[str];
        }
        for xp in extras {
            p2 = by_id[xp] as Task;
            c2 = by_id[row["id"] as str] as Task;
            p2 +>:Child:+> c2;
        }
    }
}

def build_graph(rows: list[dict]) -> TaskAnchor {
    anchor = TaskAnchor();
    root ++> anchor;
    attach_tasks(anchor, rows);
    return anchor;
}

def rollup_severity(statuses: list[str]) -> str {
    best = "ok";
    best_rank = 1;
    for st in statuses {
        rk = SEVERITY_RANK[st] as int;
        if rk > best_rank {
            best_rank = rk;
            best = st;
        }
    }
    return best;
}

walker TaskLookup {
    has tid: str;
    has claimed: dict[str, bool] = {};
    has hit: Task | None = None;

    can seek with TaskAnchor entry {
        for rt in [here ->:RootLink:->][?:Task] {
            visit rt;
        }
        print({"lookup": self.tid, "found": self.hit is not None});
    }

    can step with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        if here.tid == self.tid { self.hit = here; }
        for ch in [here ->:Child:->][?:Task] {
            visit ch;
        }
    }
}

def get_task(anchor: TaskAnchor, task_id: str) -> dict | None {
    lk = anchor spawn TaskLookup(tid=task_id);
    if lk.hit is None { return None; }
    t = lk.hit as Task;
    return {
        "id": t.tid,
        "status": t.status,
        "created_at": t.created_at,
        "sort_id": t.sort_id,
    };
}

walker ChildrenQuery {
    has parent_id: str;
    has claimed: dict[str, bool] = {};
    has child_ids: list[str] = [];

    can query with TaskAnchor entry {
        for rt in [here ->:RootLink:->][?:Task] {
            visit rt;
        }
        print({"children_of": self.parent_id, "n": len(self.child_ids)});
    }

    can pick with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        if here.tid == self.parent_id {
            for ch in [here ->:Child:->][?:Task] {
                self.child_ids.append(ch.tid);
            }
        }
        for ch in [here ->:Child:->][?:Task] {
            visit ch;
        }
    }
}

def get_children(anchor: TaskAnchor, parent_id: str) -> list[str] {
    w = anchor spawn ChildrenQuery(parent_id=parent_id);
    out: list[str] = [];
    for cid in w.child_ids { out.append(cid); }
    sorted(out);
    return out;
}

walker SubtreeWalk {
    has claimed: dict[str, bool] = {};
    has statuses: list[str] = [];

    can enter with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.statuses.append(here.status);
        print({"subtree_visit": here.tid, "status": here.status});
        for ch in [here ->:Child:->][?:Task] {
            visit :0: ch;
        }
    }
}

def get_subtree_statuses(anchor: TaskAnchor, root_id: str) -> list[str] {
    lk = anchor spawn TaskLookup(tid=root_id);
    if lk.hit is None { return []; }
    sw = lk.hit spawn SubtreeWalk();
    out: list[str] = [];
    for st in sw.statuses { out.append(st); }
    return out;
}

walker BatchRollup {
    has limit: int = 50;
    has claimed: dict[str, bool] = {};
    has active_root: str = "";
    has bucket: dict[str, list[str]] = {};
    has results: list[dict] = [];

    can begin with TaskAnchor entry {
        roots: list[Task] = [];
        for rt in [here ->:RootLink:->][?:Task] {
            roots.append(rt);
        }
        roots = sort_tasks_desc(roots);
        taken = 0;
        for rt in roots {
            if taken >= self.limit { break; }
            self.active_root = rt.tid;
            clr: dict[str, bool] = {};
            self.claimed = clr;
            empty: list[str] = [];
            self.bucket[self.active_root] = empty;
            visit rt;
            taken += 1;
        }
        idx = 0;
        for rt in roots {
            if idx >= self.limit { break; }
            sts = self.bucket[rt.tid] as list[str];
            roll = rollup_severity(sts);
            row = {
                "id": rt.tid,
                "status": rt.status,
                "created_at": rt.created_at,
                "sort_id": rt.sort_id,
                "rollup_severity": roll,
            };
            self.results.append(row);
            idx += 1;
        }
        print({"batch_rollup": len(self.results), "limit": self.limit});
    }

    can collect with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        if self.active_root != "" {
            sts = self.bucket[self.active_root] as list[str];
            sts.append(here.status);
        }
        for ch in [here ->:Child:->][?:Task] {
            visit ch;
        }
    }
}

def load_task_roots_with_rollup(anchor: TaskAnchor, limit: int = 50) -> list[dict] {
    w = anchor spawn BatchRollup(limit=limit);
    out: list[dict] = [];
    for row in w.results { out.append(row); }
    return out;
}
