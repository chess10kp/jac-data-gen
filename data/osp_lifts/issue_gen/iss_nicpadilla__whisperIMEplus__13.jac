"""nicpadilla/whisperIMEplus#13 — fork hardening roadmap implementation order."""

import from collections { deque }

class CycleError(ValueError) {}

node RoadmapItem {
    has iid: str;
    has phase: int;
    has priority: int;
}

edge Requires {}

def _pick_best(remaining: list[str], meta: dict[str, tuple[int, int]]) -> str {
    best = remaining[0];
    for iid in remaining {
        bp = meta[best];
        ip = meta[iid];
        if ip[0] < bp[0] {
            best = iid;
        } elif ip[0] == bp[0] and ip[1] > bp[1] {
            best = iid;
        } elif ip[0] == bp[0] and ip[1] == bp[1] and iid < best {
            best = iid;
        }
    }
    return best;
}

def _sort_ready(ids: list[str], meta: dict[str, tuple[int, int]]) -> list[str] {
    remaining = ids;
    out: list[str] = [];
    while len(remaining) > 0 {
        best = _pick_best(remaining, meta);
        out.append(best);
        remaining = [x for x in remaining if x != best];
    }
    return out;
}

obj RoadmapStore {
    has _root: Root;

    def init() {
        self._root = root;
    }

    def add_item(iid: str, phase: int, priority: int) -> None {
        if self._find(iid) is not None {
            raise ValueError(f"duplicate roadmap item: {iid}");
        }
        self._root ++> RoadmapItem(iid=iid, phase=phase, priority=priority);
    }

    def add_depends(item: str, dep: str) -> None {
        tgt = self._find(item);
        pred = self._find(dep);
        if tgt is None or pred is None {
            raise KeyError("unknown roadmap item id");
        }
        pred +>:Requires:+> tgt;
    }

    def find_cycle() -> list[str] {
        w = self._root spawn CycleFinder();
        if w.cycle {
            return w.cycle;
        }
        return [];
    }

    def implementation_order() -> list[str] {
        if self.find_cycle() {
            raise CycleError("cycle in fork roadmap");
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

    def _find(iid: str) -> RoadmapItem | None {
        for t in [self._root-->[?:RoadmapItem]] {
            if t.iid == iid {
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
        visit [-->][?:RoadmapItem];
    }

    can walk with RoadmapItem entry {
        if self.cycle {
            skip;
        }
        iid = here.iid;
        if iid in self.on_stack and self.on_stack[iid] {
            i = 0;
            for (idx, x) in enumerate(self.stack_ids) {
                if x == iid {
                    i = idx;
                    break;
                }
            }
            self.cycle = self.stack_ids[i:] + [iid];
            skip;
        }
        self.on_stack[iid] = True;
        self.stack_ids = self.stack_ids + [iid];
        visit [-->][?:RoadmapItem];
        self.stack_ids = self.stack_ids[:-1];
        self.on_stack[iid] = False;
    }
}

walker TopoOrder {
    has order: list[str] = [];

    can start with Root entry {
        indeg: dict[str, int] = {};
        rev: dict[str, list[str]] = {};
        meta: dict[str, tuple[int, int]] = {};
        ids: list[str] = [];
        for t in [-->][?:RoadmapItem] {
            ids.append(t.iid);
            indeg[t.iid] = 0;
            rev[t.iid] = [];
            meta[t.iid] = (t.phase, t.priority);
        }
        for t in [-->][?:RoadmapItem] {
            for p in [t<--][?:RoadmapItem] {
                indeg[t.iid] += 1;
                rev[p.iid].append(t.iid);
            }
        }
        ready = _sort_ready([i for i in ids if indeg[i] == 0], meta);
        q = deque(ready);
        while len(q) > 0 {
            u = q.popleft();
            self.order.append(u);
            for v in _sort_ready(rev.get(u, []), meta) {
                indeg[v] -= 1;
                if indeg[v] == 0 {
                    q.append(v);
                }
            }
        }
        if len(self.order) != len(ids) {
            raise CycleError("cycle in fork roadmap");
        }
    }
}

walker ReachDown {
    has start_id: str;
    has seen: list[str] = [];
    has claims: dict[str, bool] = {};

    can start with Root entry {
        for t in [-->][?:RoadmapItem] {
            if t.iid == self.start_id {
                visit [t];
            }
        }
    }

    can walk with RoadmapItem entry {
        iid = here.iid;
        if iid in self.claims {
            skip;
        }
        self.claims[iid] = True;
        self.seen.append(iid);
        visit [here-->[?:RoadmapItem]];
    }
}
