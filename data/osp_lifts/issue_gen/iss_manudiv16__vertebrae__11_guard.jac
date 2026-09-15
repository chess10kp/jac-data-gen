"""Task dependency graph — manudiv16/vertebrae#11."""

node Task {
    has tid: str;
    has short_id: str;
    has title: str;
    has archived: bool = False;
    has completed: bool = False;
}

edge Dep {}
edge Child {}

obj TaskStore {
    has tasks: dict[str, Task] = {};
}

def create_task(store: TaskStore, tid: str, title: str) -> Task {
    t = Task(tid=tid, short_id=tid[:6], title=title);
    store.tasks[tid] = t;
    return t;
}

def get_task(store: TaskStore, tid: str) -> Task | None {
    if tid in store.tasks {
        return store.tasks[tid];
    }
    return None;
}

def resolve_short_id(store: TaskStore, prefix: str) -> str {
    matches: list[str] = [];
    for k in sorted(store.tasks.keys()) {
        t = store.tasks[k];
        if t.tid.startswith(prefix) or t.short_id.startswith(prefix) {
            matches.append(t.tid);
        }
    }
    if len(matches) == 0 {
        raise ValueError("no match");
    }
    if len(matches) > 1 {
        raise ValueError("ambiguous");
    }
    return matches[0];
}

walker PathWalker {
    has goal: str;
    has claimed: dict[str, bool] = {};
    has parent_of: dict[str, str] = {};
    has found_path: list[str] = [];
    has hit: bool = False;

    can probe with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        if here.tid == self.goal {
            self.hit = True;
            cur: str = here.tid;
            path: list[str] = [];
            while cur != "" {
                path.append(cur);
                if cur in self.parent_of {
                    cur = self.parent_of[cur];
                } else {
                    cur = "";
                }
            }
            path.reverse();
            self.found_path = path;
            print({"path": self.found_path});
            disengage;
        }
        nbrs: list[Task] = [];
        for n in [here ->:Dep:->][?:Task] {
            if n.tid not in self.claimed {
                self.parent_of[n.tid] = here.tid;
                nbrs.append(n);
            }
        }
        if nbrs {
            visit nbrs;
        }
    }
}

def find_path(store: TaskStore, src_id: str, dst_id: str) -> list[str] {
    src = get_task(store, src_id);
    dst = get_task(store, dst_id);
    if (not src) or (not dst) {
        return [];
    }
    w = src spawn PathWalker(goal=dst_id);
    if w.hit {
        return w.found_path;
    }
    return [];
}

def add_dependency(store: TaskStore, task_id: str, depends_on_id: str) -> bool {
    task = get_task(store, task_id);
    dep = get_task(store, depends_on_id);
    if (not task) or (not dep) {
        return False;
    }
    if task_id == depends_on_id {
        return False;
    }
    back = find_path(store, depends_on_id, task_id);
    if len(back) > 0 {
        return False;
    }
    task +>:Dep:+> dep;
    return True;
}

walker DescendantWalker {
    has claimed: dict[str, bool] = {};
    has collected: list[str] = [];

    can walk_child with Task entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.collected.append(here.tid);
        kids: list[Task] = [];
        for ch in [here ->:Child:->][?:Task] {
            kids.append(ch);
        }
        print({"visit": here.tid, "n": len(kids)});
        if kids {
            visit kids;
        }
    }
}

def set_parent(store: TaskStore, child_id: str, parent_id: str) -> bool {
    child = get_task(store, child_id);
    parent = get_task(store, parent_id);
    if (not child) or (not parent) {
        return False;
    }
    parent +>:Child:+> child;
    return True;
}

def delete_task_cascade(store: TaskStore, tid: str) -> list[str] {
    target = get_task(store, tid);
    if not target {
        return [];
    }
    w = target spawn DescendantWalker();
    removed: list[str] = [];
    for x in w.collected {
        removed.append(x);
    }
    for rid in sorted(removed) {
        if rid in store.tasks {
            store.tasks.pop(rid);
        }
    }
    return sorted(removed);
}

def list_ready(store: TaskStore) -> list[str] {
    ready: list[str] = [];
    for k in sorted(store.tasks.keys()) {
        t = store.tasks[k];
        if t.archived or t.completed {
            continue;
        }
        blocked = False;
        for blk in [t ->:Dep:->][?:Task] {
            if not blk.completed {
                blocked = True;
                break;
            }
        }
        if not blocked {
            ready.append(t.tid);
        }
    }
    return sorted(ready);
}

test "create_and_get" {
    st = TaskStore();
    create_task(st, "task001", "First");
    assert st.tasks["task001"].title == "First";
    assert get_task(st, "task001") is not None;
    assert get_task(st, "missing") is None;
}

test "resolve_short_id_unique" {
    st = TaskStore();
    create_task(st, "alpha1", "Alpha");
    create_task(st, "beta22", "Beta");
    assert resolve_short_id(st, "alpha") == "alpha1";
}

test "find_path_and_cycle_block" {
    st = TaskStore();
    create_task(st, "a", "A");
    create_task(st, "b", "B");
    create_task(st, "c", "C");
    assert add_dependency(st, "b", "a");
    assert add_dependency(st, "c", "b");
    assert find_path(st, "c", "a") == ["c", "b", "a"];
    assert not add_dependency(st, "a", "c");
}

test "cascade_delete_sorted" {
    st = TaskStore();
    create_task(st, "p", "P");
    create_task(st, "c1", "C1");
    create_task(st, "c2", "C2");
    assert set_parent(st, "c1", "p");
    assert set_parent(st, "c2", "p");
    assert delete_task_cascade(st, "p") == ["c1", "c2", "p"];
    assert get_task(st, "p") is None;
}

test "list_ready_after_complete" {
    st = TaskStore();
    create_task(st, "a", "A");
    create_task(st, "b", "B");
    assert add_dependency(st, "b", "a");
    assert list_ready(st) == ["a"];
    st.tasks["a"].completed = True;
    assert list_ready(st) == ["b"];
}

test "delete_missing_returns_empty" {
    st = TaskStore();
    assert delete_task_cascade(st, "ghost") == [];
}
