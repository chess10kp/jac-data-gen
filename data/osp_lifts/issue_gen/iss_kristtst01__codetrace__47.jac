"""OSP lift for kristtst01/codetrace#47."""

obj CycleError(ValueError) {}

node Task {
    has task_id: str;
}

edge Depends {}

obj TaskDag {
    has tasks: dict[str, Task] = {};

    def add_task(task_id: str) -> None {
        if task_id not in self.tasks {
            t = Task(task_id=task_id);
            self.tasks[task_id] = t;
        }
    }

    def add_dependency(task_id: str, depends_on: str) -> None {
        if task_id not in self.tasks or depends_on not in self.tasks {
            raise KeyError("unknown task");
        }
        dep = self.tasks[depends_on];
        tgt = self.tasks[task_id];
        dep +>:Depends:+> tgt;
    }

    def has_cycle() -> bool {
        w = root spawn CycleProbe(tasks=self.tasks);
        return w.found;
    }

    def topological_order() -> list[str] {
        if self.has_cycle() {
            raise CycleError("cycle");
        }
        w = root spawn TopoSort(tasks=self.tasks);
        return w.order;
    }

    def ancestors(task_id: str) -> list[str] {
        if task_id not in self.tasks {
            raise KeyError("unknown task");
        }
        w = root spawn AncestorWalk(
            start=self.tasks[task_id],
            tasks=self.tasks
        );
        return sorted(w.found_ids);
    }
}

walker CycleProbe {
    has tasks: dict[str, Task];
    has claimed: dict[str, bool] = {};
    has stack: dict[str, bool] = {};
    has found: bool = False;

    can start with Root entry {
        for tid in sorted(self.tasks.keys()) {
            if not self.found {
                visit [self.tasks[tid]];
            }
        }
    }

    can dfs with Task entry {
        tid = here.task_id;
        if tid in self.stack {
            self.found = True;
            skip;
        }
        if tid in self.claimed {
            skip;
        }
        self.claimed[tid] = True;
        self.stack[tid] = True;
        visit [-->];
        del self.stack[tid];
    }
}

walker TopoSort {
    has tasks: dict[str, Task];
    has order: list[str] = [];

    can start with Root entry {
        indeg: dict[str, int] = {};
        for tid in self.tasks {
            indeg[tid] = 0;
        }
        for t in self.tasks.values() {
            for _e, child in [t -->] {
                indeg[child.task_id] += 1;
            }
        }
        ready = sorted([tid for (tid, d) in indeg.items() if d == 0]);
        while ready {
            cur_id = ready.pop(0);
            self.order.append(cur_id);
            cur = self.tasks[cur_id];
            for _e, child in [cur -->] {
                cid = child.task_id;
                indeg[cid] -= 1;
                if indeg[cid] == 0 {
                    ready.append(cid);
                    ready = sorted(ready);
                }
            }
        }
        if len(self.order) != len(self.tasks) {
            raise CycleError("cycle");
        }
    }
}

walker AncestorWalk {
    has start: Task;
    has tasks: dict[str, Task];
    has claimed: dict[str, bool] = {};
    has found_ids: list[str] = [];

    can start with Root entry {
        visit [self.start];
    }

    can walk with Task entry {
        tid = here.task_id;
        if tid in self.claimed {
            skip;
        }
        self.claimed[tid] = True;
        if here is not self.start {
            self.found_ids.append(tid);
        }
        visit [<--];
    }
}
