"""Guard: chittihq/pintail#29."""

node TableRow { has table: str; has row_id: str; has tombstoned: bool = False; }
edge FkCascade {}

obj ReplicaStore { has rows: dict[str, dict[str, TableRow]] = {}; }

walker CascadeCollect {
    has claimed: dict[str, bool] = {};
    has found: list[tuple[str, str]] = [];

    can step with TableRow entry {
        key = here.table + ":" + here.row_id;
        if key in self.claimed { skip; }
        self.claimed[key] = True;
        self.found.append((here.table, here.row_id));
        visit [->:FkCascade:->][?:TableRow] else { disengage; };
    }
}

def load_replica(
    tables: list[str],
    fk_pairs: list[tuple[str, str]],
    rows: dict[str, list[str]],
) -> ReplicaStore {
    store = ReplicaStore();
    for tbl in tables {
        store.rows[tbl] = {};
        for rid in rows.get(tbl, []) {
            nd = TableRow(table=tbl, row_id=rid);
            root ++> nd;
            store.rows[tbl][rid] = nd;
        }
    }
    for (parent, child) in fk_pairs {
        if parent not in store.rows or child not in store.rows { continue; }
        for pid in store.rows[parent].keys() {
            for cid in store.rows[child].keys() {
                pnd = store.rows[parent].get(pid, None);
                cnd = store.rows[child].get(cid, None);
                if pnd is not None and cnd is not None { pnd +>:FkCascade:+> cnd; }
            }
        }
    }
    return store;
}

def cascade_tombstone(store: ReplicaStore, table: str, row_id: str) -> list[tuple[str, str]] {
    row_map = store.rows.get(table, None);
    if row_map is None { raise KeyError("unknown row"); }
    start = row_map.get(row_id, None);
    if start is None { raise KeyError("unknown row"); }
    w = start spawn CascadeCollect(claimed={}, found=[]);
    applied: list[tuple[str, str]] = [];
    for (tbl, rid) in w.found {
        nd = store.rows.get(tbl, {}).get(rid, None);
        if nd is None or nd.tombstoned { continue; }
        nd.tombstoned = True;
        applied.append((tbl, rid));
    }
    return sorted(applied);
}

def active_rows(store: ReplicaStore, table: str) -> list[str] {
    row_map = store.rows.get(table, None);
    if row_map is None { return []; }
    live: list[str] = [];
    for (rid, nd) in row_map.items() {
        if not nd.tombstoned { live.append(rid); }
    }
    return sorted(live);
}

test "parent delete cascades child rows" {
    s = load_replica(
        ["orders", "items", "audit"],
        [("orders", "items"), ("items", "audit")],
        {"orders": ["o1"], "items": ["i1", "i2"], "audit": ["a1"]},
    );
    assert cascade_tombstone(s, "orders", "o1") == [
        ("audit", "a1"),
        ("items", "i1"),
        ("items", "i2"),
        ("orders", "o1"),
    ];
    assert active_rows(s, "orders") == [];
}

test "unknown row raises" {
    s = load_replica(["t"], [], {"t": ["r1"]});
    try {
        cascade_tombstone(s, "t", "ghost");
        assert False;
    } except KeyError {
        assert True;
    }
}

test "second tombstone idempotent" {
    s = load_replica(
        ["p", "c"],
        [("p", "c")],
        {"p": ["p1"], "c": ["c1"]},
    );
    first = cascade_tombstone(s, "p", "p1");
    second = cascade_tombstone(s, "p", "p1");
    assert len(second) == 0;
    assert len(first) == 2;
}

test "diamond fk graph once only" {
    s = load_replica(
        ["hub", "left", "right", "leaf"],
        [
            ("hub", "left"),
            ("hub", "right"),
            ("left", "leaf"),
            ("right", "leaf"),
        ],
        {
            "hub": ["h"],
            "left": ["l"],
            "right": ["r"],
            "leaf": ["x"],
        },
    );
    got = cascade_tombstone(s, "hub", "h");
    assert sorted(got) == [("hub", "h"), ("leaf", "x"), ("left", "l"), ("right", "r")];
}
