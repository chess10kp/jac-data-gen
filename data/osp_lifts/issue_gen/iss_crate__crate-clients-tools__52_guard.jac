"""crate/crate-clients-tools#52 — typeinfo_tree expansion without WITH RECURSIVE."""

node TypeRow {
    has oid: int;
    has ns: str;
    has name: str;
    has kind: str;
    has depth: int = 0;
}

edge ToBase {}
edge ToElem {}
edge ToAttr {}

walker TreeWalk {
    has claimed: dict[int, bool] = {};
    has found: list[dict[str, any]] = [];
    has store: dict[str, any] = {};

    can expand with TypeRow entry {
        if here.oid in self.claimed {
            skip;
        }
        self.claimed[here.oid] = True;
        row: dict[str, any] = {};
        row["oid"] = here.oid;
        row["ns"] = here.ns;
        row["name"] = here.name;
        row["kind"] = here.kind;
        row["depth"] = here.depth;
        self.found.append(row);
        print row;
        kids: list[TypeRow] = [];
        next_depth: int = here.depth + 1;
        for b in [here ->:ToBase:->][?:TypeRow] {
            b.depth = next_depth;
            kids.append(b);
        }
        for e in [here ->:ToElem:->][?:TypeRow] {
            e.depth = next_depth;
            kids.append(e);
        }
        for a in [here ->:ToAttr:->][?:TypeRow] {
            a.depth = next_depth;
            kids.append(a);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def make_type_store(rows: list[dict[str, any]]) -> dict[str, any] {
    store: dict[str, any] = {};
    by_oid: dict[int, TypeRow] = {};
    for r in rows {
        oid: int = int(r["oid"]);
        depth_val: int = 0;
        if "depth" in r {
            depth_val = int(r["depth"]);
        }
        nd = TypeRow(
            oid=oid,
            ns=str(r["ns"]),
            name=str(r["name"]),
            kind=str(r["kind"]),
            depth=depth_val,
        );
        root ++> nd;
        by_oid[oid] = nd;
    }
    for r in rows {
        oid: int = int(r["oid"]);
        src = by_oid[oid];
        if "basetype" in r {
            if r["basetype"] is not None {
                bt: int = int(r["basetype"]);
                if bt in by_oid {
                    dst = by_oid[bt];
                    src +>:ToBase:+> dst;
                }
            }
        }
        if "elemtype" in r {
            if r["elemtype"] is not None {
                et: int = int(r["elemtype"]);
                if et in by_oid {
                    dst = by_oid[et];
                    src +>:ToElem:+> dst;
                }
            }
        }
        if "attrtypoids" in r {
            if r["attrtypoids"] is not None {
                attrs = r["attrtypoids"];
                for ao in attrs {
                    ai: int = int(ao);
                    if ai in by_oid {
                        dst = by_oid[ai];
                        src +>:ToAttr:+> dst;
                    }
                }
            }
        }
    }
    store["by_oid"] = by_oid;
    return store;
}

def typeinfo_tree(store: dict[str, any], seed_oids: list[int]) -> list[dict[str, any]] {
    by_oid = store["by_oid"] as dict[int, TypeRow];
    claimed: dict[int, bool] = {};
    found: list[dict[str, any]] = [];
    for seed in seed_oids {
        soid: int = int(seed);
        if soid not in by_oid {
            continue;
        }
        nd = by_oid[soid];
        w = nd spawn TreeWalk(claimed=claimed, store=store);
        claimed = w.claimed;
        for item in w.found {
            found.append(item);
        }
    }
    return found;
}

with entry {
    demo_rows: list[dict[str, any]] = [];
    r1: dict[str, any] = {};
    r1["oid"] = 700;
    r1["ns"] = "pg_catalog";
    r1["name"] = "_float8";
    r1["kind"] = "b";
    demo_rows.append(r1);
    r2: dict[str, any] = {};
    r2["oid"] = 701;
    r2["ns"] = "pg_catalog";
    r2["name"] = "_float8";
    r2["kind"] = "a";
    r2["elemtype"] = 700;
    demo_rows.append(r2);
    st = make_type_store(demo_rows);
    by_oid = st["by_oid"] as dict[int, TypeRow];
    start_nd = by_oid[701];
    wk = start_nd spawn TreeWalk(claimed={}, store=st);
    print wk.found;
}

test "array_elemtype_expansion" {
    rows: list[dict[str, any]] = [];
    r1: dict[str, any] = {};
    r1["oid"] = 700;
    r1["ns"] = "pg_catalog";
    r1["name"] = "float8";
    r1["kind"] = "b";
    rows.append(r1);
    r2: dict[str, any] = {};
    r2["oid"] = 701;
    r2["ns"] = "pg_catalog";
    r2["name"] = "_float8";
    r2["kind"] = "a";
    r2["elemtype"] = 700;
    rows.append(r2);
    st = make_type_store(rows);
    out = typeinfo_tree(st, [701]);
    assert len(out) == 2;
    assert int(out[0]["oid"]) == 701;
    assert int(out[0]["depth"]) == 0;
    assert int(out[1]["oid"]) == 700;
    assert int(out[1]["depth"]) == 1;
}

test "unknown_seed_yields_empty" {
    rows: list[dict[str, any]] = [];
    r1: dict[str, any] = {};
    r1["oid"] = 1;
    r1["ns"] = "pg_catalog";
    r1["name"] = "int4";
    r1["kind"] = "b";
    rows.append(r1);
    st = make_type_store(rows);
    out = typeinfo_tree(st, [999]);
    assert len(out) == 0;
}

test "basetype_cycle_claimed_once" {
    rows: list[dict[str, any]] = [];
    r1: dict[str, any] = {};
    r1["oid"] = 100;
    r1["ns"] = "pg_catalog";
    r1["name"] = "a";
    r1["kind"] = "b";
    r1["basetype"] = 200;
    rows.append(r1);
    r2: dict[str, any] = {};
    r2["oid"] = 200;
    r2["ns"] = "pg_catalog";
    r2["name"] = "b";
    r2["kind"] = "b";
    r2["basetype"] = 100;
    rows.append(r2);
    st = make_type_store(rows);
    out = typeinfo_tree(st, [100]);
    oids: list[int] = [];
    for item in out {
        oids.append(int(item["oid"]));
    }
    assert len(out) == 2;
    assert oids == [100, 200];
}

test "shared_claim_across_seeds" {
    rows: list[dict[str, any]] = [];
    r1: dict[str, any] = {};
    r1["oid"] = 700;
    r1["ns"] = "pg_catalog";
    r1["name"] = "float8";
    r1["kind"] = "b";
    rows.append(r1);
    r2: dict[str, any] = {};
    r2["oid"] = 701;
    r2["ns"] = "pg_catalog";
    r2["name"] = "_float8";
    r2["kind"] = "a";
    r2["elemtype"] = 700;
    rows.append(r2);
    st = make_type_store(rows);
    out = typeinfo_tree(st, [701, 700]);
    oids: list[int] = [];
    for item in out {
        oids.append(int(item["oid"]));
    }
    assert len(out) == 2;
    assert oids == [701, 700];
}

test "attrtypoids_expand" {
    rows: list[dict[str, any]] = [];
    r1: dict[str, any] = {};
    r1["oid"] = 10;
    r1["ns"] = "pg_catalog";
    r1["name"] = "int4";
    r1["kind"] = "b";
    rows.append(r1);
    r2: dict[str, any] = {};
    r2["oid"] = 20;
    r2["ns"] = "pg_catalog";
    r2["name"] = "text";
    r2["kind"] = "b";
    rows.append(r2);
    r3: dict[str, any] = {};
    r3["oid"] = 30;
    r3["ns"] = "pg_catalog";
    r3["name"] = "rowtype";
    r3["kind"] = "c";
    attrs: list[int] = [];
    attrs.append(10);
    attrs.append(20);
    r3["attrtypoids"] = attrs;
    rows.append(r3);
    st = make_type_store(rows);
    out = typeinfo_tree(st, [30]);
    oids: list[int] = [];
    for item in out {
        oids.append(int(item["oid"]));
    }
    assert len(out) == 3;
    assert oids == [30, 20, 10];
}
