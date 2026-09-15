"""DAG traversal engine for task prerequisite validation.

Source: rajat-wyrm/InternOps#1969
"""

node Task {
    has tid: str;
}

edge Depends {}

obj TaskEngine {
    has registry: dict[str, Task] = {};

    def get_or_create(self, tid: str) -> Task {
        if tid in self.registry {
            return self.registry[tid];
        }
        nd = Task(tid=tid);
        self.registry[tid] = nd;
        root ++> nd;
        return nd;
    }

    def add_dependency(self, prerequisite: str, dependent: str) {
        pre = self.get_or_create(prerequisite);
        dep = self.get_or_create(dependent);
        pre +>:Depends:+> dep;
    }
}

walker CycleProbe {
    has inflight: dict[str, bool] = {};
    has finished: dict[str, bool] = {};
    has cyclic: bool = False;

    can probe with Task entry {
        if here.tid in self.inflight and self.inflight[here.tid] {
            self.cyclic = True;
            print(f"cycle at {here.tid}");
            skip;
        }
        if here.tid in self.finished {
            skip;
        }
        self.inflight[here.tid] = True;
        kids: list[Task] = [here ->:Depends:->][?:Task];
        for ch in kids {
            visit ch;
        }
        self.finished[here.tid] = True;
        self.inflight[here.tid] = False;
        print(f"probed {here.tid}");
    }
}

walker TopoWalk {
    has finished: dict[str, bool] = {};
    has seq: list[str] = [];

    can walk with Task entry {
        if here.tid in self.finished {
            skip;
        }
        self.finished[here.tid] = True;
        self.seq.append(here.tid);
        kids: list[Task] = [here ->:Depends:->][?:Task];
        for ch in kids {
            visit :0: ch;
        }
        print(f"topo {here.tid}");
    }
}

def create_task_engine -> TaskEngine {
    return TaskEngine();
}

def add_dependency(engine: TaskEngine, prerequisite: str, dependent: str) {
    engine.add_dependency(prerequisite, dependent);
}

def _collect_roots(engine: TaskEngine) -> list[Task] {
    incoming: dict[str, bool] = {};
    roots: list[Task] = [];
    for tid in engine.registry {
        nd = engine.registry[tid];
        kids: list[Task] = [nd ->:Depends:->][?:Task];
        for ch in kids {
            incoming[ch.tid] = True;
        }
    }
    for tid in engine.registry {
        if tid not in incoming {
            roots.append(engine.registry[tid]);
        }
    }
    if not roots and engine.registry {
        first_tid = sorted(engine.registry.keys())[0];
        roots.append(engine.registry[first_tid]);
    }
    return roots;
}

def has_cycle(engine: TaskEngine) -> bool {
    roots = _collect_roots(engine);
    for r in roots {
        wk = r spawn CycleProbe(inflight={}, finished={});
        print(f"cycle_probe root={r.tid} cyclic={wk.cyclic}");
        if wk.cyclic {
            return True;
        }
    }
    return False;
}

def topological_sort(engine: TaskEngine) -> list[str] {
    if has_cycle(engine) {
        return [];
    }
    roots = _collect_roots(engine);
    merged: list[str] = [];
    placed: dict[str, bool] = {};
    for r in roots {
        wk = r spawn TopoWalk(finished={});
        print(f"topo_walk root={r.tid} count={len(wk.seq)}");
        for tid in wk.seq {
            if tid not in placed {
                placed[tid] = True;
                merged.append(tid);
            }
        }
    }
    return merged;
}

def can_add_dependency(engine: TaskEngine, prerequisite: str, dependent: str) -> bool {
    if prerequisite == dependent {
        return False;
    }
    pre = engine.get_or_create(prerequisite);
    dep = engine.get_or_create(dependent);
    pre +>:Depends:+> dep;
    if has_cycle(engine) {
        dep <:Depends:< pre;
        return False;
    }
    return True;
}
