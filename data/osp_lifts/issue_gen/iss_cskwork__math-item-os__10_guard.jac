"""Prerequisite edge service — cskwork/math-item-os#10."""

node Item {
    has cid: str;
}

edge Prereq {}

walker DepReachWalker {
    has target: str;
    has claimed: dict[str, bool] = {};
    has found: bool = False;

    can follow with Item entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print("reach", here.cid);
        if here.cid == self.target {
            self.found = True;
            disengage;
        }
        deps: list[Item] = [here ->:Prereq:->][?:Item];
        if len(deps) > 0 {
            visit :0: deps;
        } else {
            disengage;
        }
    }
}

obj PrereqService {
    has by_id: dict[str, Item] = {};

    def _get(self, cid: str) -> Item | None {
        if cid in self.by_id {
            return self.by_id[cid];
        }
        return None;
    }

    def _ensure(self, cid: str) -> Item {
        existing = self._get(cid);
        if existing is not None {
            return existing;
        }
        nd = Item(cid=cid);
        root ++> nd;
        self.by_id[cid] = nd;
        return nd;
    }

    def would_create_cycle(self, item_id: str, prereq_id: str) -> bool {
        if item_id == prereq_id {
            return True;
        }
        prereq_nd = self._get(prereq_id);
        item_nd = self._get(item_id);
        if prereq_nd is None or item_nd is None {
            return False;
        }
        w = prereq_nd spawn DepReachWalker(target=item_id, claimed={});
        print("cycle_check", item_id, prereq_id, w.found);
        return w.found;
    }

    def add_prerequisite(self, item_id: str, prereq_id: str) -> bool {
        if self.would_create_cycle(item_id, prereq_id) {
            return False;
        }
        item_nd = self._ensure(item_id);
        prereq_nd = self._ensure(prereq_id);
        prereq_nd +>:Prereq:+> item_nd;
        print("added", prereq_id, "->", item_id);
        return True;
    }

    def list_prerequisites(self, item_id: str) -> list[str] {
        item_nd = self._get(item_id);
        if item_nd is None {
            out: list[str] = [];
            return out;
        }
        preds: list[Item] = [?:Item <-:Prereq:-<][item_nd];
        out: list[str] = [];
        for p in preds {
            out.append(p.cid);
        }
        return sorted(out);
    }

    def has_prerequisite(self, item_id: str, prereq_id: str) -> bool {
        reqs = self.list_prerequisites(item_id);
        for r in reqs {
            if r == prereq_id {
                return True;
            }
        }
        return False;
    }
}

def make_service -> PrereqService {
    return PrereqService(by_id={});
}

"""Prerequisite edge service — cskwork/math-item-os#10."""

node Item {
    has cid: str;
}

edge Prereq {}

walker DepReachWalker {
    has target: str;
    has claimed: dict[str, bool] = {};
    has found: bool = False;

    can follow with Item entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print("reach", here.cid);
        if here.cid == self.target {
            self.found = True;
            disengage;
        }
        deps: list[Item] = [here ->:Prereq:->][?:Item];
        if len(deps) > 0 {
            visit :0: deps;
        } else {
            disengage;
        }
    }
}

obj PrereqService {
    has by_id: dict[str, Item] = {};

    def _get(self, cid: str) -> Item | None {
        if cid in self.by_id {
            return self.by_id[cid];
        }
        return None;
    }

    def _ensure(self, cid: str) -> Item {
        existing = self._get(cid);
        if existing is not None {
            return existing;
        }
        nd = Item(cid=cid);
        root ++> nd;
        self.by_id[cid] = nd;
        return nd;
    }

    def would_create_cycle(self, item_id: str, prereq_id: str) -> bool {
        if item_id == prereq_id {
            return True;
        }
        prereq_nd = self._get(prereq_id);
        item_nd = self._get(item_id);
        if prereq_nd is None or item_nd is None {
            return False;
        }
        w = prereq_nd spawn DepReachWalker(target=item_id, claimed={});
        print("cycle_check", item_id, prereq_id, w.found);
        return w.found;
    }

    def add_prerequisite(self, item_id: str, prereq_id: str) -> bool {
        if self.would_create_cycle(item_id, prereq_id) {
            return False;
        }
        item_nd = self._ensure(item_id);
        prereq_nd = self._ensure(prereq_id);
        prereq_nd +>:Prereq:+> item_nd;
        print("added", prereq_id, "->", item_id);
        return True;
    }

    def list_prerequisites(self, item_id: str) -> list[str] {
        item_nd = self._get(item_id);
        if item_nd is None {
            out: list[str] = [];
            return out;
        }
        preds: list[Item] = [?:Item <-:Prereq:-<][item_nd];
        out: list[str] = [];
        for p in preds {
            out.append(p.cid);
        }
        return sorted(out);
    }

    def has_prerequisite(self, item_id: str, prereq_id: str) -> bool {
        reqs = self.list_prerequisites(item_id);
        for r in reqs {
            if r == prereq_id {
                return True;
            }
        }
        return False;
    }
}

def make_service -> PrereqService {
    return PrereqService(by_id={});
}

test "add_and_list" {
    svc = make_service();
    ok = svc.add_prerequisite("B", "A");
    assert ok == True;
    reqs = svc.list_prerequisites("B");
    assert reqs == ["A"];
}

test "self_cycle_blocked" {
    svc = make_service();
    assert svc.would_create_cycle("A", "A") == True;
    assert svc.add_prerequisite("A", "A") == False;
}

test "indirect_cycle_blocked" {
    svc = make_service();
    svc.add_prerequisite("B", "A");
    svc.add_prerequisite("C", "B");
    assert svc.would_create_cycle("A", "C") == True;
    assert svc.add_prerequisite("A", "C") == False;
}

test "unknown_item_empty_list" {
    svc = make_service();
    reqs = svc.list_prerequisites("missing");
    assert reqs == [];
}

test "has_prerequisite" {
    svc = make_service();
    svc.add_prerequisite("B", "A");
    assert svc.has_prerequisite("B", "A") == True;
    assert svc.has_prerequisite("B", "X") == False;
}

test "missing_nodes_no_cycle" {
    svc = make_service();
    assert svc.would_create_cycle("A", "B") == False;
}
