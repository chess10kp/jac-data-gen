# manudiv16/vertebrae#2 — TaskService dependency graph core (BFS path, cycle guard, cascade delete)

node GraphRoot {}

node Task {
    has id: str;
    has short_id: str;
    has title: str;
    has archived: bool = False;
    has completed_at: str = "";
}

edge DependsOn {}
edge ParentOf {}

walker PathFinder {
    has start_id: str;
    has target: str;
    has found: list[str] = [];
    has claimed: dict[str, bool] = {};
    has parent: dict[str, str] = {};
    has hit: bool = False;

    can bfs with Task entry {
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        print ["path_visit", here.id];
        if here.id == self.target {
            self.hit = True;
            cur: str = here.id;
            rev: list[str] = [];
            while cur != "" {
                rev.append(cur);
                if cur == self.start_id { break; }
                if cur in self.parent {
                    cur = self.parent[cur];
                } else {
                    cur = "";
                }
            }
            self.found = [];
            i: int = len(rev) - 1;
            while i >= 0 {
                self.found.append(rev[i]);
                i -= 1;
            }
            disengage;
        }
        deps: list[Task] = [here ->:DependsOn:->][?:Task];
        if len(deps) > 0 {
            for dep in deps {
                if dep.id not in self.parent {
                    self.parent[dep.id] = here.id;
                }
                visit [dep];
            }
        } else {
            disengage;
        }
    }
}

walker DescendantCollector {
    has claimed: dict[str, bool] = {};
    has to_delete: list[str] = [];

    can gather with Task entry {
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        print ["cascade_collect", here.id];
        self.to_delete.append(here.id);
        kids: list[Task] = [here ->:ParentOf:->][?:Task];
        for kid in kids {
            visit :0: [kid];
        }
    }
}

def short_id_of(task_id: str) -> str {
    if len(task_id) >= 6 {
        return task_id[0:6];
    }
    return task_id;
}

def find_task(graph_root: GraphRoot, task_id: str) -> Task | None {
    tasks: list[Task] = graph_root -->> Task;
    for t in tasks {
        if t.id == task_id {
            return t;
        }
    }
    return None;
}

def create_task(graph_root: GraphRoot, task_id: str, title: str) -> Task {
    t = Task(
        id=task_id,
        short_id=short_id_of(task_id),
        title=title
    );
    graph_root ++> t;
    return t;
}

def set_parent(graph_root: GraphRoot, child_id: str, parent_id: str) -> bool {
    child: Task | None = find_task(graph_root, child_id);
    parent: Task | None = find_task(graph_root, parent_id);
    if child is None or parent is None {
        return False;
    }
    parent +>:ParentOf:+> child;
    return True;
}

def find_path(graph_root: GraphRoot, from_id: str, to_id: str) -> list[str] | None {
    if from_id == to_id {
        if find_task(graph_root, from_id) is None {
            return None;
        }
        return [from_id];
    }
    start: Task | None = find_task(graph_root, from_id);
    if start is None {
        return None;
    }
    w = start spawn PathFinder(start_id=from_id, target=to_id);
    if w.hit {
        return w.found;
    }
    return None;
}

def add_dependency(graph_root: GraphRoot, task_id: str, depends_on_id: str) -> bool {
    task: Task | None = find_task(graph_root, task_id);
    dep: Task | None = find_task(graph_root, depends_on_id);
    if task is None or dep is None {
        return False;
    }
    if task_id == depends_on_id {
        raise ValueError("cycle");
    }
    back: list[str] | None = find_path(graph_root, depends_on_id, task_id);
    if back is not None {
        raise ValueError("cycle");
    }
    task +>:DependsOn:+> dep;
    return True;
}

def get_dependencies(graph_root: GraphRoot, task_id: str) -> list[str] {
    task: Task | None = find_task(graph_root, task_id);
    if task is None {
        return [];
    }
    out: list[str] = [];
    deps: list[Task] = [task ->:DependsOn:->][?:Task];
    for d in deps {
        out.append(d.id);
    }
    return sorted(out);
}

def delete_task(graph_root: GraphRoot, task_id: str, cascade: bool = False) -> bool {
    task: Task | None = find_task(graph_root, task_id);
    if task is None {
        return False;
    }
    ids: list[str] = [task_id];
    if cascade {
        w = task spawn DescendantCollector();
        ids = sorted(w.to_delete);
    }
    i: int = len(ids) - 1;
    while i >= 0 {
        tid: str = ids[i];
        victim: Task | None = find_task(graph_root, tid);
        if victim is not None {
            destroy victim;
        }
        i -= 1;
    }
    return True;
}

def resolve_short_id(graph_root: GraphRoot, prefix: str) -> str {
    matches: list[str] = [];
    tasks: list[Task] = graph_root -->> Task;
    for t in tasks {
        if t.short_id.startswith(prefix) or t.id.startswith(prefix) {
            matches.append(t.id);
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
