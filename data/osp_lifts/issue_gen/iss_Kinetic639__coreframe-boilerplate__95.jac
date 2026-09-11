"""Kinetic639/coreframe-boilerplate#95 — category hierarchy (OSP lift)."""

class CycleError(ValueError) {}

node Category {
    has cat_id: str;
}

edge ChildOf {}

obj CategoryTree {
    has _root: Root;

    def init() {
        self._root = root;
    }

    def add_category(cat_id: str) -> None {
        if self._find(cat_id) is not None {
            raise ValueError(f"duplicate category: {cat_id}");
        }
        self._root ++> Category(cat_id=cat_id);
    }

    def add_child(parent_id: str, child_id: str) -> None {
        p = self._find(parent_id);
        c = self._find(child_id);
        if p is None or c is None {
            raise KeyError("unknown category id");
        }
        p +>:ChildOf:+> c;
    }

    def descendants(cat_id: str) -> list[str] {
        n = self._find(cat_id);
        if n is None {
            return [];
        }
        w = self._root spawn DescendWalker(start_id=cat_id);
        return sorted(w.seen);
    }

    def ancestors(cat_id: str) -> list[str] {
        n = self._find(cat_id);
        if n is None {
            return [];
        }
        w = self._root spawn AncestorWalker(start_id=cat_id);
        return sorted(w.seen);
    }

    def find_cycle() -> list[str] {
        w = self._root spawn CycleFinder();
        return w.cycle if w.cycle else [];
    }

    def _find(cat_id: str) -> Category | None {
        for c in [self._root-->[?:Category]] {
            if c.cat_id == cat_id {
                return c;
            }
        }
        return None;
    }
}

walker DescendWalker {
    has start_id: str;
    has seen: list[str] = [];
    has claims: dict[str, bool] = {};

    can start with Root entry {
        for c in [-->][?:Category] {
            if c.cat_id == self.start_id {
                visit [c];
            }
        }
    }

    can walk with Category entry {
        cid = here.cat_id;
        if cid in self.claims {
            skip;
        }
        self.claims[cid] = True;
        self.seen.append(cid);
        visit [here->:ChildOf:->];
    }
}

walker AncestorWalker {
    has start_id: str;
    has seen: list[str] = [];
    has claims: dict[str, bool] = {};

    can start with Root entry {
        for c in [-->][?:Category] {
            if c.cat_id == self.start_id {
                for p in [c<--][?:Category] {
                    visit [p];
                }
            }
        }
    }

    can walk with Category entry {
        cid = here.cat_id;
        if cid in self.claims {
            skip;
        }
        self.claims[cid] = True;
        self.seen.append(cid);
        for p in [here<--][?:Category] {
            visit [p];
        }
    }
}

walker CycleFinder {
    has cycle: list[str] = [];
    has on_stack: dict[str, bool] = {};
    has stack_ids: list[str] = [];

    can start with Root entry {
        visit [-->][?:Category];
    }

    can walk with Category entry {
        if self.cycle {
            skip;
        }
        cid = here.cat_id;
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
        visit [here->:ChildOf:->];
        self.stack_ids = self.stack_ids[:-1];
        self.on_stack[cid] = False;
    }
}
