"""dunay2/dvt#2594 — bounded Substrait card pipeline (OSP lift)."""

import from collections { deque }

class CycleError(ValueError) {}

node Card {
    has card_id: str;
}

edge Depends {}

obj CardPipeline {
    has _root: Root;

    def init() {
        self._root = root;
    }

    def add_card(card_id: str) -> None {
        self._root ++> Card(card_id=card_id);
    }

    def depends(card: str, dep: str) -> None {
        tgt = self._find(card);
        pred = self._find(dep);
        if tgt is None or pred is None {
            raise KeyError("unknown card id");
        }
        pred +>:Depends:+> tgt;
    }

    def linearize() -> list[str] {
        w = self._root spawn CycleFinder();
        if w.cycle {
            raise CycleError("cycle in card pipeline");
        }
        w2 = self._root spawn TopoOrder();
        return w2.order;
    }

    def downstream(card_id: str) -> list[str] {
        n = self._find(card_id);
        if n is None {
            return [];
        }
        w = self._root spawn ReachDown(start_id=card_id);
        return sorted(w.seen);
    }

    def _find(card_id: str) -> Card | None {
        for c in [self._root-->[?:Card]] {
            if c.card_id == card_id {
                return c;
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
        visit [-->][?:Card];
    }

    can walk with Card entry {
        if self.cycle {
            skip;
        }
        cid = here.card_id;
        if cid in self.on_stack and self.on_stack[cid] {
            i = 0;
            for (idx, x) in enumerate(self.stack_ids) {
                if x == cid {
                    i = idx;
                    break;
                }
            }
            self.cycle = self.stack_ids[i:] + [cid];
            skip;
        }
        self.on_stack[cid] = True;
        self.stack_ids = self.stack_ids + [cid];
        visit [-->][?:Card];
        self.stack_ids = self.stack_ids[:-1];
        self.on_stack[cid] = False;
    }
}

walker TopoOrder {
    has order: list[str] = [];

    can start with Root entry {
        indeg: dict[str, int] = {};
        rev: dict[str, list[str]] = {};
        ids: list[str] = [];
        for c in [-->][?:Card] {
            ids.append(c.card_id);
            indeg[c.card_id] = 0;
            rev[c.card_id] = [];
        }
        for c in [-->][?:Card] {
            for p in [c<--][?:Card] {
                indeg[c.card_id] += 1;
                rev[p.card_id].append(c.card_id);
            }
        }
        q = deque(sorted([i for i in ids if indeg[i] == 0]));
        while len(q) > 0 {
            u = q.popleft();
            self.order.append(u);
            for v in sorted(rev.get(u, [])) {
                indeg[v] -= 1;
                if indeg[v] == 0 {
                    q.append(v);
                }
            }
        }
        if len(self.order) != len(ids) {
            raise CycleError("cycle in card pipeline");
        }
    }
}

walker ReachDown {
    has start_id: str;
    has seen: list[str] = [];
    has claims: dict[str, bool] = {};

    can start with Root entry {
        for c in [-->][?:Card] {
            if c.card_id == self.start_id {
                visit [c];
            }
        }
    }

    can walk with Card entry {
        cid = here.card_id;
        if cid in self.claims {
            skip;
        }
        self.claims[cid] = True;
        self.seen.append(cid);
        visit [here-->[?:Card]];
    }
}
