"""OSP lift for sqlc-dev/sqlc#3730 — recursive tag ancestor closure."""

node Tag {
    has cid: str;
    has tag_id: int;
    has name: str;
    has parent_id: int;
}

edge ParentLink {}

walker TagRecursiveWalk {
    has claimed: dict[str, bool] = {};
    has found: list[Tag] = [];

    can step with Tag entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here);
        print("visit ", here.tag_id);
        nexts: list[Tag] = [];
        for nxt in [here ->:ParentLink:->][?:Tag] {
            nexts.append(nxt);
        }
        if nexts {
            visit :0: nexts;
        } else {
            disengage;
        }
    }
}

def create_tag_store -> dict {
    nodes: dict[str, Tag] = {};
    st: dict = {};
    st["nodes"] = nodes;
    st["wired"] = False;
    return st;
}

def add_tag(st: dict, tag_id: int, name: str, parent: int) {
    nodes = st["nodes"] as dict[str, Tag];
    cid = str(tag_id);
    nd = Tag(cid=cid, tag_id=tag_id, name=name, parent_id=parent);
    root ++> nd;
    nodes[cid] = nd;
    st["wired"] = False;
}

def wire_parent_edges(st: dict) {
    if st["wired"] as bool {
        return;
    }
    nodes = st["nodes"] as dict[str, Tag];
    keys: list[str] = [];
    for k in nodes {
        keys.append(k);
    }
    sorted_keys = sorted(keys);
    for cid in sorted_keys {
        nd = nodes[cid];
        pk = str(nd.parent_id);
        if pk in nodes {
            if pk != cid {
                par = nodes[pk];
                nd +>:ParentLink:+> par;
            }
        }
    }
    st["wired"] = True;
}

def tag_row(nd: Tag) -> dict {
    row: dict = {};
    row["id"] = nd.tag_id;
    row["name"] = nd.name;
    row["parent"] = nd.parent_id;
    return row;
}

def get_tag_recursive(st: dict, start_id: int) -> list[dict] {
    wire_parent_edges(st);
    nodes = st["nodes"] as dict[str, Tag];
    sk = str(start_id);
    if not (sk in nodes) {
        return [];
    }
    origin = nodes[sk];
    w = origin spawn TagRecursiveWalk(claimed={});
    rows: list[dict] = [];
    for nd in w.found {
        rows.append(tag_row(nd));
    }
    return rows;
}

test "unknown_start_empty" {
    st = create_tag_store();
    add_tag(st, 1, "a", 0);
    got = get_tag_recursive(st, 999);
    assert len(got) == 0;;
}

test "single_root_tag" {
    st = create_tag_store();
    add_tag(st, 1, "root", 0);
    got = get_tag_recursive(st, 1);
    assert len(got) == 1;;
    assert got[0]["id"] == 1;;
    assert got[0]["name"] == "root";;
}

test "ancestor_chain_ordered" {
    st = create_tag_store();
    add_tag(st, 1, "child", 2);
    add_tag(st, 2, "parent", 3);
    add_tag(st, 3, "root", 0);
    got = get_tag_recursive(st, 1);
    ids: list[int] = [];
    for r in got {
        ids.append(r["id"] as int);
    }
    assert ids == [1, 2, 3];;
}

test "cycle_claim_map_skips_revisit" {
    st = create_tag_store();
    add_tag(st, 1, "a", 2);
    add_tag(st, 2, "b", 1);
    got = get_tag_recursive(st, 1);
    ids: list[int] = [];
    for r in got {
        ids.append(r["id"] as int);
    }
    sorted_ids = sorted(ids);
    assert sorted_ids == [1, 2];;
    assert len(got) == 2;;
}

test "wire_parent_edges_idempotent" {
    st = create_tag_store();
    add_tag(st, 10, "leaf", 20);
    add_tag(st, 20, "mid", 0);
    wire_parent_edges(st);
    first = get_tag_recursive(st, 10);
    second = get_tag_recursive(st, 10);
    assert len(first) == len(second);;
    assert first[0]["id"] == second[0]["id"];;
}
