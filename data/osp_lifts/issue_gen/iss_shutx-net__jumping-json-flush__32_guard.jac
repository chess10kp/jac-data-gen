node Table {
    has tid: str;
    has logical: str;
}
node DbRoot {
    has did: str;
}
edge HasTable {}
edge Depends {}

walker Reach {
    has claimed: dict[str, bool] = {};
    has out: list[str] = [];
    can step with Table entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        self.out.append(here.tid);
        print(here.tid);
        for nxt in [here ->:Depends:->][?:Table] {
            visit [nxt];
        }
    }
}

def find_table(db: DbRoot, tid: str) -> Table | None {
    for t in [db ->:HasTable:->][?:Table] {
        if t.tid == tid { return t; }
    }
    return None;
}

def make_db(did: str) -> DbRoot {
    db = DbRoot(did=did);
    root ++> db;
    return db;
}

def add_table(db: DbRoot, tid: str, logical: str) -> Table {
    exist = find_table(db, tid);
    if exist is not None {
        return exist as Table;
    }
    nd = Table(tid=tid, logical=logical);
    db +>:HasTable:+> nd;
    return nd;
}

def add_fk(db: DbRoot, src: str, dst: str) -> bool {
    s = find_table(db, src);
    d = find_table(db, dst);
    if s is None { return False; }
    if d is None { return False; }
    src_nd = s as Table;
    dst_nd = d as Table;
    src_nd +>:Depends:+> dst_nd;
    return True;
}

def reachable(db: DbRoot, start: str) -> list[str] {
    s = find_table(db, start);
    if s is None { return []; }
    tbl = s as Table;
    w = tbl spawn Reach(claimed={}, out=[]);
    return sorted(w.out);
}

def has_cycle(db: DbRoot) -> bool {
    tables: list[Table] = [];
    for t in [db ->:HasTable:->][?:Table] {
        tables.append(t);
    }
    for t in tables {
        succs: list[Table] = [];
        for nxt in [t ->:Depends:->][?:Table] {
            succs.append(nxt);
        }
        for nxt in succs {
            w = nxt spawn Reach(claimed={}, out=[]);
            if t.tid in w.out { return True; }
        }
    }
    return False;
}

def build_order(db: DbRoot) -> list[str] {
    if has_cycle(db) { return []; }
    out: list[str] = [];
    for t in [db ->:HasTable:->][?:Table] {
        out.append(t.tid);
    }
    return sorted(out);
}

with entry {
    root spawn Reach(claimed={}, out=[]);
    demo: DbRoot = make_db("demo");
    a: Table = add_table(demo, "a", "A");
    b: Table = add_table(demo, "b", "B");
    _ok: bool = add_fk(demo, "a", "b");
    w2 = a spawn Reach(claimed={}, out=[]);
    print(sorted(w2.out));
}

test "diamond revisit adversarial order" {
    db: DbRoot = make_db("d1");
    a: Table = add_table(db, "a", "A");
    b: Table = add_table(db, "b", "B");
    c: Table = add_table(db, "c", "C");
    d: Table = add_table(db, "d", "D");
    _a = add_fk(db, "a", "b");
    _b = add_fk(db, "a", "c");
    _c = add_fk(db, "b", "d");
    _d = add_fk(db, "c", "d");
    r: list[str] = reachable(db, "a");
    assert sorted(r) == ["a", "b", "c", "d"];
    assert len(r) == 4;
}

test "unknown id tolerance" {
    db: DbRoot = make_db("u1");
    _t = add_table(db, "a", "A");
    assert reachable(db, "missing") == [];
    assert has_cycle(db) == False;
    assert add_fk(db, "a", "missing") == False;
    assert add_fk(db, "missing", "a") == False;
    assert build_order(db) == ["a"];
}

test "cycle detection and closure" {
    db: DbRoot = make_db("c1");
    _a = add_table(db, "a", "A");
    _b = add_table(db, "b", "B");
    _c = add_table(db, "c", "C");
    _ab = add_fk(db, "a", "b");
    _bc = add_fk(db, "b", "c");
    _ca = add_fk(db, "c", "a");
    assert has_cycle(db) == True;
    r: list[str] = reachable(db, "a");
    assert sorted(r) == ["a", "b", "c"];
    assert build_order(db) == [];
}

test "build order acyclic sorted" {
    db: DbRoot = make_db("o1");
    _z = add_table(db, "z", "Z");
    _x = add_table(db, "x", "X");
    _y = add_table(db, "y", "Y");
    _xy = add_fk(db, "x", "y");
    _yz = add_fk(db, "y", "z");
    assert has_cycle(db) == False;
    o: list[str] = build_order(db);
    assert o == sorted(o);
    assert len(o) == 3;
    assert reachable(db, "x") == ["x", "y", "z"];
}
