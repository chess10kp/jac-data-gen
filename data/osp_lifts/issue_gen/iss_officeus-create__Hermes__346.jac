"""officeus-create/Hermes#346 — revenue-first master backlog execution order."""

import from collections { deque }

class CycleError(ValueError) {}

node BacklogItem {
    has tid: str;
    has revenue: int;
}

edge Blocks {}

def _pick_best(remaining: list[str], rev_map: dict[str, int]) -> str {
    best = remaining[0];
    for tid in remaining {
        if rev_map[tid] > rev_map[best] {
            best = tid;
        } elif rev_map[tid] == rev_map[best] and tid < best {
            best = tid;
        }
    }
    return best;
}

def _sort_revenue_first(ids: list[str], rev_map: dict[str, int]) -> list[str] {
    remaining = ids;
    out: list[str] = [];
    while len(remaining) > 0 {
        best = _pick_best(remaining, rev_map);
        out.append(best);
        remaining = [x for x in remaining if x != best];
    }
    return out;
}

obj BacklogStore {
    has _root: Root;

    def init() {
        self._root = root;
    }

    def add_task(tid: str, revenue: int) -> None {
        if self._find(tid) is not None {
            raise ValueError(f"duplicate task: {tid}");
        }
        self._root ++> BacklogItem(tid=tid, revenue=revenue);
    }

    def add_depends(t: str, dep: str) -> None {
        src = self._find(t);
        pred = self._find(dep);
        if src is None or pred is None {
            raise KeyError("unknown task id");
        }
        pred +>:Blocks:+> src;
    }

    def find_cycle() -> list[str] {
        w = self._root spawn CycleFinder();
        if w.cycle {
            return w.cycle;
        }
        return [];
    }

    def execution_order() -> list[str] {
        if self.find_cycle() {
            raise CycleError("cycle in backlog dag");
        }
        w = self._root spawn TopoOrder();
        return w.order;
    }

    def reachable_from(start: str) -> list[str] {
        n = self._find(start);
        if n is None {
            return [];
        }
        w = self._root spawn ReachDown(start_id=start);
        return sorted(w.seen);
    }

    def _find(tid: str) -> BacklogItem | None {
        for t in [self._root-->[?:BacklogItem]] {
            if t.tid == tid {
                return t;
            }
        }
        return None;
    }
}

walker CycleFinder {
    has cycle: list[str] = [];
    has on_stack: dict[str, bool] = {};
    has stack_ids: list[str] = [];

    can start with Root entry {
        visit [-->][?:BacklogItem];
    }

    can walk with BacklogItem entry {
        if self.cycle {
            skip;
        }
        tid = here.tid;
        if tid in self.on_stack and self.on_stack[tid] {
            i = 0;
            for (idx, x) in enumerate(self.stack_ids) {
                if x == tid {
                    i = idx;
                    break;
                }
            }
            self.cycle = self.stack_ids[i:] + [tid];
            skip;
        }
        self.on_stack[tid] = True;
        self.stack_ids = self.stack_ids + [tid];
        visit [-->][?:BacklogItem];
        self.stack_ids = self.stack_ids[:-1];
        self.on_stack[tid] = False;
    }
}

walker TopoOrder {
    has order: list[str] = [];

    can start with Root entry {
        indeg: dict[str, int] = {};
        rev: dict[str, list[str]] = {};
        rev_map: dict[str, int] = {};
        ids: list[str] = [];
        for t in [-->][?:BacklogItem] {
            ids.append(t.tid);
            indeg[t.tid] = 0;
            rev[t.tid] = [];
            rev_map[t.tid] = t.revenue;
        }
        for t in [-->][?:BacklogItem] {
            for p in [t<--][?:BacklogItem] {
                indeg[t.tid] += 1;
                rev[p.tid].append(t.tid);
            }
        }
        ready = _sort_revenue_first([i for i in ids if indeg[i] == 0], rev_map);
        q = deque(ready);
        while len(q) > 0 {
            u = q.popleft();
            self.order.append(u);
            for v in _sort_revenue_first(rev.get(u, []), rev_map) {
                indeg[v] -= 1;
                if indeg[v] == 0 {
                    q.append(v);
                }
            }
        }
        if len(self.order) != len(ids) {
            raise CycleError("cycle in backlog dag");
        }
    }
}

walker ReachDown {
    has start_id: str;
    has seen: list[str] = [];
    has claims: dict[str, bool] = {};

    can start with Root entry {
        for t in [-->][?:BacklogItem] {
            if t.tid == self.start_id {
                visit [t];
            }
        }
    }

    can walk with BacklogItem entry {
        tid = here.tid;
        if tid in self.claims {
            skip;
        }
        self.claims[tid] = True;
        self.seen.append(tid);
        visit [here-->[?:BacklogItem]];
    }
}
