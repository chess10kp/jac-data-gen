"""backspring-labs/squad-ops#578 — candidate + hidden guards."""

# --- candidate (duplicate or import-equivalent of .jac module body) ---
# Paste the full iss_backspring-labs__squad-ops__578.jac content here,
# then append tests below. Filename MUST be *_guard.jac (single dot).

import from collections { deque }

class CycleError(ValueError) {}

node PlanTask {
    has task_id: str;
}

edge Depends {}

obj PlanStore {
    has _root: Root;
    def init() { self._root = root; }
    def add_task(task_id: str) -> None { self._root ++> PlanTask(task_id=task_id); }
    def add_depends_on(task_id: str, depends_on: str) -> None {
        src = self._find(task_id);
        dep = self._find(depends_on);
        if not src or not dep { raise KeyError("unknown task id"); }
        dep +>:Depends:+> src;
    }
    def find_cycle() -> list[str] {
        w = self._root spawn CycleFinder();
        return w.cycle if w.cycle else [];
    }
    def execution_order() -> list[str] {
        if self.find_cycle() { raise CycleError("cycle in plan dag"); }
        w = self._root spawn TopoOrder();
        return w.order;
    }
    def reachable_from(start: str) -> list[str] {
        n = self._find(start);
        if not n { return []; }
        w = self._root spawn ReachDown(start_id=start);
        visit n;
        return sorted(w.seen);
    }
    def _find(task_id: str) -> PlanTask | None {
        for t in [self._root-->[?:PlanTask]] {
            if t.task_id == task_id { return t; }
        }
        return None;
    }
}

walker CycleFinder {
    has cycle: list[str] = [];
    has on_stack: dict[str, bool] = {};
    has stack_ids: list[str] = [];
    can start with Root entry { visit [-->][?:PlanTask]; }
    can walk with PlanTask entry {
        if self.cycle { skip; }
        tid = here.task_id;
        if tid in self.on_stack and self.on_stack[tid] {
            i = 0;
            for (idx, x) in enumerate(self.stack_ids) {
                if x == tid { i = idx; break; }
            }
            self.cycle = self.stack_ids[i:] + [tid];
            skip;
        }
        self.on_stack[tid] = True;
        self.stack_ids = self.stack_ids + [tid];
        visit [-->][?:PlanTask];
        self.stack_ids = self.stack_ids[:-1];
        self.on_stack[tid] = False;
    }
}

walker TopoOrder {
    has order: list[str] = [];
    can start with Root entry {
        indeg: dict[str, int] = {};
        rev: dict[str, list[str]] = {};
        ids: list[str] = [];
        for t in [-->][?:PlanTask] {
            ids.append(t.task_id);
            indeg[t.task_id] = 0;
            rev[t.task_id] = [];
        }
        for t in [-->][?:PlanTask] {
            for p in [t<--][?:PlanTask] {
                indeg[t.task_id] += 1;
                rev[p.task_id].append(t.task_id);
            }
        }
        q = deque(sorted([i for i in ids if indeg[i] == 0]));
        while len(q) > 0 {
            u = q.popleft();
            self.order.append(u);
            for v in sorted(rev.get(u, [])) {
                indeg[v] -= 1;
                if indeg[v] == 0 { q.append(v); }
            }
        }
        if len(self.order) != len(ids) { raise CycleError("cycle in plan dag"); }
    }
}

walker ReachDown {
    has start_id: str;
    has seen: list[str] = [];
    has claims: dict[str, bool] = {};
    can start with Root entry {
        for t in [-->][?:PlanTask] {
            if t.task_id == self.start_id { visit [t]; }
        }
    }
    can walk with PlanTask entry {
        tid = here.task_id;
        if tid in self.claims { skip; }
        self.claims[tid] = True;
        self.seen.append(tid);
        visit [here-->[?:PlanTask]];
    }
}

# --- hidden guards (pin Python semantics) ---

def _build_acyclic() -> PlanStore {
    s = PlanStore();
    for t in ["a", "b", "c", "d"] { s.add_task(t); }
    s.add_depends_on("b", "a");
    s.add_depends_on("c", "a");
    s.add_depends_on("d", "b");
    s.add_depends_on("d", "c");
    return s;
}

def _build_cycle() -> PlanStore {
    s = PlanStore();
    for t in ["x", "y", "z"] { s.add_task(t); }
    s.add_depends_on("y", "x");
    s.add_depends_on("z", "y");
    s.add_depends_on("x", "z");
    return s;
}

def _build_diamond() -> PlanStore {
    s = PlanStore();
    for t in ["root", "left", "right", "join"] { s.add_task(t); }
    s.add_depends_on("join", "left");
    s.add_depends_on("join", "right");
    s.add_depends_on("left", "root");
    s.add_depends_on("right", "root");
    return s;
}

test "acyclic order" {
    s = _build_acyclic();
    assert s.find_cycle() == [];
    assert s.execution_order() == ["a", "b", "c", "d"];
}

test "cycle detected multiset" {
    s = _build_cycle();
    cyc = s.find_cycle();
    assert len(cyc) >= 2;
    assert sorted(set(cyc)) == ["x", "y", "z"];
    try {
        s.execution_order();
        assert False, "expected CycleError";
    } except CycleError {
        assert True;
    }
}

test "diamond adversarial order and reach" {
    s = _build_diamond();
    assert s.find_cycle() == [];
    assert s.execution_order() == ["root", "left", "right", "join"];
    assert s.reachable_from("root") == ["join", "left", "right", "root"];
}

test "unknown id KeyError" {
    s = _build_acyclic();
    try {
        s.add_depends_on("missing", "a");
        assert False, "expected KeyError";
    } except KeyError {
        assert True;
    }
}
