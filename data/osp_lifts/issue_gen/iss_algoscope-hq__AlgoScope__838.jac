"""Topological ordering for a task dependency DAG.

Issue: algoscope-hq/AlgoScope#838
https://github.com/algoscope-hq/AlgoScope/issues/838
"""

node Task {
    has task_id: str;
}

edge Dep {}

class CycleError(ValueError) {}

obj TaskGraph {
    has tasks: dict[str, Task] = {};

    def add_task(task_id: str) -> None {
        if task_id in self.tasks {
            return;
        }
        t = Task(task_id=task_id);
        self.tasks[task_id] = t;
        root ++> t;
    }

    def add_dependency(before_id: str, after_id: str) -> None {
        self.add_task(before_id);
        self.add_task(after_id);
        b = self.tasks[before_id];
        a = self.tasks[after_id];
        b +>:Dep:+> a;
    }

    def has_cycle() -> bool {
        try {
            _ = self.topological_order_kahn();
        } except CycleError {
            return True;
        }
        return False;
    }

    def topological_order_kahn() -> list[str] {
        w = root spawn KahnTopo(task_ids=sorted(self.tasks.keys()));
        if w.cycle {
            raise CycleError("cycle detected");
        }
        return w.order;
    }

    def topological_order_dfs() -> list[str] {
        w = root spawn DfsTopo(task_ids=sorted(self.tasks.keys()));
        if w.cycle {
            raise CycleError("cycle detected");
        }
        return w.order;
    }

    def reachable_from(start_id: str) -> list[str] {
        if start_id not in self.tasks {
            return [];
        }
        w = root spawn ReachCollect(start_id=start_id);
        return sorted(w.seen);
    }
}

walker KahnTopo {
    has task_ids: list[str] = [];
    has order: list[str] = [];
    has cycle: bool = False;
    has indeg: dict[str, int] = {};
    has claimed: dict[str, bool] = {};

    can count_in with Task entry {
        tid = here.task_id;
        if (tid in self.claimed) {
            skip;
        }
        self.claimed[tid] = True;
        self.indeg[tid] = self.indeg.get(tid, 0);
        visit [-->][?:Task];
        for succ in [-->][?:Task] {
            sid = succ.task_id;
            self.indeg[sid] = self.indeg.get(sid, 0) + 1;
        }
    }

    can peel with Task entry {
        tid = here.task_id;
        if self.indeg.get(tid, 0) != 0 {
            disengage;
        }
        if (tid in self.claimed) {
            skip;
        }
        self.claimed[tid] = True;
        self.order.append(tid);
        for succ in [-->][?:Task] {
            sid = succ.task_id;
            self.indeg[sid] = self.indeg.get(sid, 1) - 1;
        }
        visit [-->][?:Task];
    }

    can start with Root entry {
        self.claimed = {};
        root spawn self.__class__(task_ids=self.task_ids);
        visit [-->][?:Task];
        if len(self.order) != len(self.task_ids) {
            self.cycle = True;
        }
    }
}

walker DfsTopo {
    has task_ids: list[str] = [];
    has order: list[str] = [];
    has cycle: bool = False;
    has finished: dict[str, bool] = {};
    has onstack: dict[str, bool] = {};

    can dfs with Task entry {
        tid = here.task_id;
        if (tid in self.onstack) {
            self.cycle = True;
            skip;
        }
        if (tid in self.finished) {
            skip;
        }
        self.onstack[tid] = True;
        visit [-->][?:Task];
        del self.onstack[tid];
        self.finished[tid] = True;
        self.order.append(tid);
    }

    can start with Root entry {
        visit [-->][?:Task];
        self.order.reverse();
    }
}

walker ReachCollect {
    has start_id: str;
    has seen: list[str] = [];
    has claimed: dict[str, bool] = {};

    can walk with Task entry {
        tid = here.task_id;
        if (tid in self.claimed) {
            skip;
        }
        self.claimed[tid] = True;
        if tid != self.start_id {
            self.seen.append(tid);
        }
        visit [-->][?:Task];
    }

    can start with Root entry {
        if self.start_id not in {t.task_id for t in [-->][?:Task]} {
            disengage;
        }
        visit [-->][?:Task];
    }
}
