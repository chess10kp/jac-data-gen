"""kurtzace/diary-2026#3 — recursive CTE hierarchy, closure, and rank windows."""

obj OrgStore {
    has by_eid: dict[str, Employee] = {};
    has seq: int = 0;
}

node Employee {
    has cid: str;
    has eid: str;
    has name: str;
    has revenue: int = 0;
}

edge ReportsTo {}

walker DescendWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Employee entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.order.append(here.eid);
        print {"descend": here.eid};
        kids: list[Employee] = [here ->:ReportsTo:->][?:Employee];
        for ch in kids {
            visit :0: [ch];
        }
    }
}

walker AncestorWalker {
    has claimed: dict[str, bool] = {};
    has chain: list[str] = [];

    can climb with Employee entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.chain.append(here.eid);
        print {"climb": here.eid};
        moms: list[Employee] = [<-:ReportsTo:<-][?:Employee];
        for p in moms {
            visit :0: [p];
        }
    }
}

walker LevelWalker {
    has claimed: dict[str, bool] = {};
    has lv: dict[str, int] = {};
    has cur_depth: int = 0;

    can measure with Employee entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.lv[here.eid] = self.cur_depth;
        depth_val = self.cur_depth;
        print {"level": here.eid, "d": depth_val};
        kids: list[Employee] = [here ->:ReportsTo:->][?:Employee];
        for ch in kids {
            self.cur_depth += 1;
            visit :0: [ch];
            self.cur_depth -= 1;
        }
    }
}

def create_store -> OrgStore {
    return OrgStore();
}

def add_employee(
    store: OrgStore,
    eid: str,
    name: str,
    revenue: int,
    manager_eid: str | None = None,
) {
    store.seq += 1;
    cid = "n" + str(store.seq);
    nd = Employee(cid=cid, eid=eid, name=name, revenue=revenue);
    store.by_eid[eid] = nd;
    root ++> nd;
    if manager_eid is not None {
        if manager_eid in store.by_eid {
            mgr = store.by_eid[manager_eid] as Employee;
            mgr +>:ReportsTo:+> nd;
        }
    }
}

def descendant_closure(store: OrgStore, root_eid: str) -> list[str] {
    if root_eid not in store.by_eid {
        return [];
    }
    nd = store.by_eid[root_eid] as Employee;
    w = nd spawn DescendWalker(claimed={});
    return w.order;
}

def ancestor_chain(store: OrgStore, eid: str) -> list[str] {
    if eid not in store.by_eid {
        return [];
    }
    nd = store.by_eid[eid] as Employee;
    w = nd spawn AncestorWalker(claimed={});
    return w.chain;
}

def level_map(store: OrgStore, root_eid: str) -> dict[str, int] {
    out: dict[str, int] = {};
    if root_eid not in store.by_eid {
        return out;
    }
    nd = store.by_eid[root_eid] as Employee;
    w = nd spawn LevelWalker(claimed={}, cur_depth=0);
    keys: list[str] = [];
    for k in w.lv {
        keys.append(k);
    }
    for k in keys {
        out[k] = w.lv[k];
    }
    return out;
}

def rank_sales(store: OrgStore) -> list[tuple[str, int, int]] {
    items: list[tuple[str, int]] = [];
    eids: list[str] = sorted(store.by_eid.keys());
    for eid in eids {
        emp = store.by_eid[eid] as Employee;
        items.append((eid, emp.revenue));
    }
    n = len(items);
    i = 0;
    while i < n {
        j = i + 1;
        while j < n {
            a_rev = items[i][1];
            b_rev = items[j][1];
            a_id = items[i][0];
            b_id = items[j][0];
            swap = False;
            if a_rev < b_rev {
                swap = True;
            } elif a_rev == b_rev and a_id > b_id {
                swap = True;
            }
            if swap {
                tmp = items[i];
                items[i] = items[j];
                items[j] = tmp;
            }
            j += 1;
        }
        i += 1;
    }
    out: list[tuple[str, int, int]] = [];
    idx = 0;
    dense = 0;
    prev_rev = -1;
    while idx < n {
        rev = items[idx][1];
        rank_skip = idx + 1;
        if rev != prev_rev {
            dense += 1;
            prev_rev = rev;
        }
        out.append((items[idx][0], rank_skip, dense));
        idx += 1;
    }
    return out;
}
