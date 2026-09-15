"""Task graph algorithms module. painted-porch/marcus#72"""

node Task {
    has tid: str;
    has duration: int = 0;
}

edge Depends {}

obj TaskGraph {
    has anchor: Task | None = None;
    has index: dict[str, Task] = {};

    def get_task(tid: str) -> Task | None {
        if tid in self.index {
            return self.index[tid];
        }
        return None;
    }

    def add_task(task: Task) {
        self.index[task.tid] = task;
        if self.anchor is None {
            self.anchor = task;
        }
    }
}

walker CycleProbe {
    has found: bool = False;
    has stack: dict[str, bool] = {};
    has claimed: dict[str, bool] = {};

    can probe with Task entry {
        if here.tid in self.claimed {
            skip;
        }
        if here.tid in self.stack {
            self.found = True;
            print("cycle", here.tid);
            skip;
        }
        self.stack[here.tid] = True;
        print("probe", here.tid);
        deps: list[Task] = [];
        for dep in [here ->:Depends:->][?:Task] {
            deps.append(dep);
        }
        for dep in deps {
            visit dep;
        }
        self.stack[here.tid] = False;
        self.claimed[here.tid] = True;
    }
}

walker TopoCollect {
    has order: list[str] = [];
    has claimed: dict[str, bool] = {};

    can collect with Task entry {
        if here.tid in self.claimed {
            skip;
        }
        print("topo", here.tid);
        deps: list[Task] = [];
        for dep in [here ->:Depends:->][?:Task] {
            deps.append(dep);
        }
        for dep in deps {
            visit dep;
        }
        self.claimed[here.tid] = True;
        self.order.append(here.tid);
    }
}

walker DfsWalker {
    has order: list[str] = [];
    has claimed: dict[str, bool] = {};

    can walk with Task entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        self.order.append(here.tid);
        print("dfs", here.tid);
        kids: list[Task] = [];
        for dep in [here ->:Depends:->][?:Task] {
            kids.append(dep);
        }
        visit :0: kids;
    }
}

walker BfsWalker {
    has order: list[str] = [];
    has claimed: dict[str, bool] = {};
    has queue: list[Task] = [];

    can walk with Task entry {
        if here.tid in self.claimed {
            skip;
        }
        self.claimed[here.tid] = True;
        self.order.append(here.tid);
        print("bfs", here.tid);
        for dep in [here ->:Depends:->][?:Task] {
            if dep.tid not in self.claimed {
                queued: bool = False;
                for q in self.queue {
                    if q.tid == dep.tid {
                        queued = True;
                    }
                }
                if not queued {
                    self.queue.append(dep);
                }
            }
        }
        if len(self.queue) > 0 {
            nxt: Task = self.queue[0];
            rest: list[Task] = [];
            for i in range(1, len(self.queue)) {
                rest.append(self.queue[i]);
            }
            self.queue = rest;
            visit nxt;
        } else {
            disengage;
        }
    }
}

def build_task_graph(
    task_ids: list[str],
    durations: list[int],
    dep_from: list[str],
    dep_to: list[str]
) -> TaskGraph {
    g = TaskGraph();
    i: int = 0;
    while i < len(task_ids) {
        t = Task(tid=task_ids[i], duration=durations[i]);
        root ++> t;
        g.add_task(t);
        i += 1;
    }
    j: int = 0;
    while j < len(dep_from) {
        src: Task | None = g.get_task(dep_from[j]);
        dst: Task | None = g.get_task(dep_to[j]);
        if src is not None and dst is not None {
            src +>:Depends:+> dst;
        }
        j += 1;
    }
    return g;
}

def _sorted_task_ids(graph: TaskGraph) -> list[str] {
    ids: list[str] = [];
    for k in graph.index {
        ids.append(k);
    }
    return sorted(ids);
}

def has_cycle(graph: TaskGraph) -> bool {
    seeds: list[str] = _sorted_task_ids(graph);
    shared: dict[str, bool] = {};
    for tid in seeds {
        if tid in shared {
            continue;
        }
        t: Task | None = graph.get_task(tid);
        if t is None {
            continue;
        }
        w = t spawn CycleProbe(found=False, stack={}, claimed=shared);
        if w.found {
            return True;
        }
    }
    return False;
}

def topological_sort(graph: TaskGraph) -> list[str] {
    merged: list[str] = [];
    shared: dict[str, bool] = {};
    seeds: list[str] = _sorted_task_ids(graph);
    for tid in seeds {
        if tid in shared {
            continue;
        }
        t: Task | None = graph.get_task(tid);
        if t is None {
            continue;
        }
        w = t spawn TopoCollect(claimed=shared);
        for x in w.order {
            merged.append(x);
            shared[x] = True;
        }
    }
    return merged;
}

def dfs_order(graph: TaskGraph, start_id: str) -> list[str] {
    start: Task | None = graph.get_task(start_id);
    if start is None {
        return [];
    }
    w = start spawn DfsWalker(claimed={});
    return w.order;
}

def bfs_order(graph: TaskGraph, start_id: str) -> list[str] {
    start: Task | None = graph.get_task(start_id);
    if start is None {
        return [];
    }
    w = start spawn BfsWalker(claimed={}, queue=[]);
    return w.order;
}

def critical_path_length(graph: TaskGraph) -> int {
    if has_cycle(graph) {
        return -1;
    }
    order: list[str] = topological_sort(graph);
    best: dict[str, int] = {};
    for tid in order {
        best[tid] = 0;
    }
    for tid in order {
        t: Task = graph.index[tid];
        mx: int = 0;
        for dep in [t ->:Depends:->][?:Task] {
            if dep.tid in best {
                if best[dep.tid] > mx {
                    mx = best[dep.tid];
                }
            }
        }
        best[tid] = t.duration + mx;
    }
    result: int = 0;
    for tid in best {
        if best[tid] > result {
            result = best[tid];
        }
    }
    return result;
}

test "build_and_lookup" {
    g = build_task_graph(["a", "b"], [1, 2], ["b"], ["a"]);
    t = g.get_task("b");
    assert t is not None;
    assert t.duration == 2;
    assert g.get_task("missing") is None;
}

test "has_cycle_acyclic" {
    g = build_task_graph(["a", "b", "c"], [1, 2, 3], ["b", "c"], ["a", "b"]);
    assert has_cycle(g) == False;
}

test "has_cycle_cyclic" {
    g = build_task_graph(["a", "b"], [1, 1], ["a", "b"], ["b", "a"]);
    assert has_cycle(g) == True;
}

test "topological_sort_order" {
    g = build_task_graph(["a", "b", "c"], [1, 2, 3], ["b", "c"], ["a", "b"]);
    assert topological_sort(g) == ["a", "b", "c"];
}

test "dfs_and_bfs_from_start" {
    g = build_task_graph(["a", "b", "c"], [1, 2, 3], ["b", "c"], ["a", "b"]);
    assert dfs_order(g, "c") == ["c", "b", "a"];
    assert bfs_order(g, "c") == ["c", "b", "a"];
}

test "critical_path_length" {
    g = build_task_graph(["a", "b", "c"], [1, 2, 3], ["b", "c"], ["a", "b"]);
    assert critical_path_length(g) == 6;
    cyc = build_task_graph(["a", "b"], [1, 1], ["a", "b"], ["b", "a"]);
    assert critical_path_length(cyc) == -1;
}
