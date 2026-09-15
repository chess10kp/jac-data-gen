"""Recursive CTE hierarchy lift — adrianbrowning/prisma-ts-select#162."""

node Entity {
    has eid: str;
    has label: str;
    has depth: int = 0;
}

edge ParentOf {}

glob ANCHOR_PROJECTION: list[str] = ["eid", "label", "depth"];
glob RECUR_PROJECTION: list[str] = ["eid", "label", "depth"];

def columns_compatible(anchor_cols: list[str], member_cols: list[str]) -> bool {
    if len(anchor_cols) != len(member_cols) {
        return False;
    }
    for i in range(len(anchor_cols)) {
        if anchor_cols[i] != member_cols[i] {
            return False;
        }
    }
    return True;
}

def project_row(nd: Entity, fields: list[str]) -> dict[str, any] {
    out: dict[str, any] = {};
    for f in fields {
        if f == "eid" {
            out["eid"] = nd.eid;
        } elif f == "label" {
            out["label"] = nd.label;
        } elif f == "depth" {
            out["depth"] = nd.depth;
        }
    }
    return out;
}

def discover_entities(graph_root: __root__) -> dict[str, Entity] {
    idx: dict[str, Entity] = {};
    claimed: dict[str, bool] = {};
    wk = graph_root spawn DiscoverEntities(idx=idx, claimed=claimed);
    return wk.idx;
}

walker DiscoverEntities {
    has idx: dict[str, Entity];
    has claimed: dict[str, bool] = {};

    can begin with __root__ entry {
        tops: list[Entity] = [here ++>(`?Entity)];
        for top in tops {
            visit [top];
        }
        print ["discover_begin", len(tops)];
    }

    can step with Entity entry {
        if here.eid in self.claimed {
            skip;
        }
        self.claimed[here.eid] = True;
        self.idx[here.eid] = here;
        print ["discover", here.eid];
        kids: list[Entity] = [here ->:ParentOf:->][?:Entity];
        for kid in kids {
            visit [kid];
        }
        uppers: list[Entity] = [here <-:ParentOf:<-][?:Entity];
        for up in uppers {
            visit [up];
        }
    }
}

walker RecursiveMember {
    has claimed: dict[str, bool] = {};
    has rows: list[dict[str, any]] = [];
    has fields: list[str] = [];

    can expand with Entity entry {
        if here.eid in self.claimed {
            skip;
        }
        self.claimed[here.eid] = True;
        row: dict[str, any] = project_row(here, self.fields);
        self.rows.append(row);
        print ["recursive_member", here.eid, here.depth];
        kids: list[Entity] = [here ->:ParentOf:->][?:Entity];
        if kids {
            for kid in kids {
                kid.depth = here.depth + 1;
                visit :0: [kid];
            }
        } else {
            disengage;
        }
    }
}

def with_recursive_union(
    graph_root: __root__,
    anchor_ids: list[str],
    fields: list[str],
) -> list[dict[str, any]] {
    idx: dict[str, Entity] = discover_entities(graph_root);
    rows: list[dict[str, any]] = [];
    claimed: dict[str, bool] = {};
    for aid in anchor_ids {
        if aid not in idx {
            continue;
        }
        anchor_nd: Entity = idx[aid];
        anchor_nd.depth = 0;
        wk = anchor_nd spawn RecursiveMember(claimed=claimed, rows=rows, fields=fields);
        claimed = wk.claimed;
        rows = wk.rows;
    }
    return rows;
}

test "columns_compatible_equal" {
    assert (columns_compatible(ANCHOR_PROJECTION, RECUR_PROJECTION));;
}

test "columns_compatible_diff_len" {
    assert (not columns_compatible(["eid"], ["eid", "label"]));;
}

test "recursive_union_linear_depths" {
    e1 = Entity(eid="a", label="A");
    e2 = Entity(eid="b", label="B");
    e3 = Entity(eid="c", label="C");
    root ++> e1;
    e1 +>:ParentOf:+> e2;
    e2 +>:ParentOf:+> e3;
    rows = with_recursive_union(root, ["a"], ["eid", "depth"]);
    eids: list[str] = [];
    depths: list[int] = [];
    for r in rows {
        eids.append(r["eid"] as str);
        depths.append(r["depth"] as int);
    }
    assert (eids == ["a", "b", "c"]);;
    assert (depths == [0, 1, 2]);;
}

test "recursive_union_skips_unknown_anchor" {
    e1 = Entity(eid="x", label="X");
    root ++> e1;
    rows = with_recursive_union(root, ["missing", "x"], ["eid"]);
    assert (len(rows) == 1);;
    assert ((rows[0]["eid"] as str) == "x");;
}

test "recursive_union_dedup_diamond" {
    e1 = Entity(eid="1", label="one");
    e2 = Entity(eid="2", label="two");
    e3 = Entity(eid="3", label="three");
    e4 = Entity(eid="4", label="four");
    root ++> e1;
    e1 +>:ParentOf:+> e2;
    e1 +>:ParentOf:+> e3;
    e2 +>:ParentOf:+> e4;
    e3 +>:ParentOf:+> e4;
    rows = with_recursive_union(root, ["1"], ["eid"]);
    eids: list[str] = [];
    for r in rows {
        eids.append(r["eid"] as str);
    }
    assert (len(eids) == 4);;
    assert (sorted(eids) == ["1", "2", "3", "4"]);;
    count4 = 0;
    for e in eids {
        if e == "4" {
            count4 += 1;
        }
    }
    assert (count4 == 1);;
}
