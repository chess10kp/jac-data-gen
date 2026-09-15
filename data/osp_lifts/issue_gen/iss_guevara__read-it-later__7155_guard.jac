"""Closure table hierarchy maintenance — guevara/read-it-later#7155."""

node Nomen {
    has nid: int;
    has name: str;
}

edge ParentE {}

node ClosureStore {
    has by_nid: dict[int, Nomen] = {};
}

walker RebuildWalker {
    has claimed: dict[str, bool] = {};
    has rows: list[tuple[int, int, int]] = [];
    has path: list[int] = [];

    can step with Nomen entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.rows.append((here.nid, here.nid, 0));
        d: int = 1;
        for anc_nid in self.path {
            self.rows.append((here.nid, anc_nid, d));
            d = d + 1;
        }
        self.path.append(here.nid);
        kids: list[Nomen] = [here ->:ParentE:->][?:Nomen];
        for kid in kids {
            visit :0: [kid];
        }
        if len(self.path) > 0 {
            self.path.pop();
        }
        print (here.nid, len(self.rows));
    }
}

walker DescWalker {
    has claimed: dict[str, bool] = {};
    has target: int = 0;
    has found: bool = False;

    can descend with Nomen entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if here.nid == self.target {
            self.found = True;
        }
        kids: list[Nomen] = [here ->:ParentE:->][?:Nomen];
        for kid in kids {
            visit :0: [kid];
        }
        print (here.nid, self.found);
    }
}

def make_store() -> ClosureStore {
    st = ClosureStore(by_nid={});
    root ++> st;
    return st;
}

def clear_parent_edge(ch: Nomen) {
    pars: list[Nomen] = [ch <-:ParentE:<-][?:Nomen];
    for p in pars {
        p del--> ch;
    }
}

def rebuild_closure(store: ClosureStore) -> list[tuple[int, int, int]] {
    rows: list[tuple[int, int, int]] = [];
    roots: list[Nomen] = [];
    for nid in store.by_nid {
        nd: Nomen = store.by_nid[nid];
        pars: list[Nomen] = [nd <-:ParentE:<-][?:Nomen];
        if len(pars) == 0 {
            roots.append(nd);
        }
    }
    for r in roots {
        claimed: dict[str, bool] = {};
        wrows: list[tuple[int, int, int]] = [];
        wpath: list[int] = [];
        w = r spawn RebuildWalker(claimed=claimed, rows=wrows, path=wpath);
        for row in w.rows {
            rows.append(row);
        }
    }
    return sorted(rows);
}

def would_create_cycle(store: ClosureStore, nid: int, new_parent_nid: int) -> bool {
    if new_parent_nid == 0 {
        return False;
    }
    if nid not in store.by_nid {
        return False;
    }
    if new_parent_nid not in store.by_nid {
        return False;
    }
    src: Nomen = store.by_nid[nid];
    claimed: dict[str, bool] = {};
    w = src spawn DescWalker(claimed=claimed, target=new_parent_nid, found=False);
    return w.found;
}

def add_nomen(store: ClosureStore, nid: int, name: str, parent_nid: int) -> list[tuple[int, int, int]] {
    nd = Nomen(nid=nid, name=name);
    root ++> nd;
    store.by_nid[nid] = nd;
    if parent_nid != 0 {
        if parent_nid in store.by_nid {
            par: Nomen = store.by_nid[parent_nid];
            par +>:ParentE:+> nd;
        }
    }
    return rebuild_closure(store);
}

def reparent_node(store: ClosureStore, nid: int, new_parent_nid: int) -> tuple[bool, list[tuple[int, int, int]]] {
    cur: list[tuple[int, int, int]] = rebuild_closure(store);
    if nid not in store.by_nid {
        return (False, cur);
    }
    if would_create_cycle(store, nid, new_parent_nid) {
        return (False, cur);
    }
    ch: Nomen = store.by_nid[nid];
    clear_parent_edge(ch);
    if new_parent_nid != 0 {
        if new_parent_nid in store.by_nid {
            par: Nomen = store.by_nid[new_parent_nid];
            par +>:ParentE:+> ch;
        }
    }
    nxt: list[tuple[int, int, int]] = rebuild_closure(store);
    return (True, nxt);
}

def ancestors_of(rows: list[tuple[int, int, int]], nid: int) -> list[tuple[int, int]] {
    out: list[tuple[int, int]] = [];
    for row in rows {
        if row[0] == nid and row[1] != nid {
            out.append((row[1], row[2]));
        }
    }
    return sorted(out);
}

def descendants_of(rows: list[tuple[int, int, int]], nid: int) -> list[tuple[int, int]] {
    out: list[tuple[int, int]] = [];
    for row in rows {
        if row[1] == nid and row[0] != nid {
            out.append((row[0], row[2]));
        }
    }
    return sorted(out);
}

with entry {
    st: ClosureStore = make_store();
    add_nomen(st, 1, "root", 0);
    seed: Nomen = st.by_nid[1];
    claimed: dict[str, bool] = {};
    wrows: list[tuple[int, int, int]] = [];
    wpath: list[int] = [];
    w = seed spawn RebuildWalker(claimed=claimed, rows=wrows, path=wpath);
    print len(w.rows);
}

test "closure_rebuild_three_node" {
    st = make_store();
    add_nomen(st, 1, "a", 0);
    add_nomen(st, 2, "b", 1);
    rows = add_nomen(st, 3, "c", 2);
    exp: list[tuple[int, int, int]] = [(1, 1, 0), (2, 1, 1), (2, 2, 0), (3, 1, 2), (3, 2, 1), (3, 3, 0)];
    assert rows == exp;;
}

test "ancestors_and_descendants" {
    st = make_store();
    add_nomen(st, 1, "a", 0);
    add_nomen(st, 2, "b", 1);
    rows = add_nomen(st, 3, "c", 2);
    anc: list[tuple[int, int]] = [(1, 2), (2, 1)];
    des: list[tuple[int, int]] = [(2, 1), (3, 2)];
    assert ancestors_of(rows, 3) == anc;;
    assert descendants_of(rows, 1) == des;;
}

test "would_create_cycle_detects_loop" {
    st = make_store();
    add_nomen(st, 1, "a", 0);
    add_nomen(st, 2, "b", 1);
    add_nomen(st, 3, "c", 2);
    assert would_create_cycle(st, 1, 3) == True;;
    assert would_create_cycle(st, 3, 1) == False;;
}

test "reparent_success_updates_closure" {
    st = make_store();
    add_nomen(st, 1, "a", 0);
    add_nomen(st, 2, "b", 1);
    add_nomen(st, 3, "c", 2);
    ok, rows = reparent_node(st, 3, 1);
    exp: list[tuple[int, int, int]] = [(1, 1, 0), (2, 1, 1), (2, 2, 0), (3, 1, 1), (3, 3, 0)];
    assert ok == True;;
    assert rows == exp;;
}

test "reparent_blocked_on_cycle" {
    st = make_store();
    add_nomen(st, 1, "a", 0);
    add_nomen(st, 2, "b", 1);
    before = add_nomen(st, 3, "c", 2);
    ok, after = reparent_node(st, 1, 3);
    assert ok == False;;
    assert after == before;;
}

test "reparent_unknown_node" {
    st = make_store();
    cur = add_nomen(st, 1, "a", 0);
    ok, rows = reparent_node(st, 99, 1);
    assert ok == False;;
    assert rows == cur;;
}
