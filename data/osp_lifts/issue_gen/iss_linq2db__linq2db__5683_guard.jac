"""Synthetic lift for linq2db/linq2db#5683 — recursive CTE column survival."""

glob REQUIRED_COLS = ["RootPartSortField", "RootPartId", "PartId", "HierarchyLevel"];

node Part {
    has cid: str;
    has pid: int;
    has sort_key: str;
    has depth: int = 0;
}

edge ParentRef {}

walker CteWalker {
    has claimed: dict[str, bool] = {};
    has root_pid: int = 0;
    has root_sort: str = "";
    has rows: list[dict] = [];

    can walk with Part entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.depth == 0 {
            self.root_sort = here.sort_key;
        }
        row: dict = {};
        row["RootPartSortField"] = self.root_sort;
        row["RootPartId"] = self.root_pid;
        row["PartId"] = here.pid;
        row["HierarchyLevel"] = here.depth;
        self.rows.append(row);
        print(f"cte PartId={here.pid} level={here.depth}");
        kids: list[Part] = [];
        for ch in [here ->:ParentRef:->][?:Part] {
            ch.depth = here.depth + 1;
            kids.append(ch);
        }
        if kids {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def required_cte_columns -> list[str] {
    out: list[str] = [];
    for c in REQUIRED_COLS {
        out.append(c);
    }
    return sorted(out);
}

def anchor_fields -> list[str] {
    return required_cte_columns();
}

def recursive_fields_derived -> list[str] {
    # Convert-wrapped derived branch must retain join-only columns
    out: list[str] = [];
    for c in REQUIRED_COLS {
        out.append(c);
    }
    return sorted(out);
}

def merge_set_operation_columns(use_recursive: bool) -> list[str] {
    if use_recursive {
        return recursive_fields_derived();
    }
    return anchor_fields();
}

def unwrap_convert_branch(fields: list[str]) -> list[str] {
    out: list[str] = [];
    for f in fields {
        out.append(f);
    }
    return sorted(out);
}

def index_parts(parts: list[dict]) -> dict[str, Part] {
    nodes: dict[str, Part] = {};
    for p in parts {
        cid = f"p{p['id']}";
        nd = Part(cid=cid, pid=p["id"], sort_key=str(p.get("name", "")), depth=0);
        nodes[cid] = nd;
        root ++> nd;
    }
    return nodes;
}

def wire_refs(nodes: dict[str, Part], refs: list[dict]) {
    for r in refs {
        pc = f"p{r['parent_id']}";
        cc = f"p{r['reference_id']}";
        if pc not in nodes { continue; }
        if cc not in nodes { continue; }
        parent = nodes[pc] as Part;
        child = nodes[cc] as Part;
        parent +>:ParentRef:+> child;
    }
}

def traverse_hierarchy(parts: list[dict], refs: list[dict], anchor_ids: list[int]) -> list[dict] {
    nodes = index_parts(parts);
    wire_refs(nodes, refs);
    all_rows: list[dict] = [];
    ids: list[int] = [];
    for aid in anchor_ids {
        ids.append(aid);
    }
    sorted_ids: list[int] = sorted(ids);
    for aid in sorted_ids {
        key = f"p{aid}";
        if key not in nodes { continue; }
        anchor = nodes[key] as Part;
        w = anchor spawn CteWalker(claimed={}, root_pid=aid);
        for row in w.rows {
            all_rows.append(row);
        }
    }
    return all_rows;
}

with entry {
    demo_parts = [{"id": 1, "name": "anchor"}];
    demo_refs: list[dict] = [];
    _ = traverse_hierarchy(demo_parts, demo_refs, [1]);
}

test "merge_retains_required_columns" {
    base = anchor_fields();
    derived = recursive_fields_derived();
    merged = merge_set_operation_columns(True);
    assert len(base) == 4;;
    assert len(derived) == 4;;
    assert merged == required_cte_columns();;
}

test "unwrap_convert_preserves_fields" {
    raw = recursive_fields_derived();
    unwrapped = unwrap_convert_branch(raw);
    assert unwrapped == anchor_fields();;
}

test "diamond_revisit_skip_not_disengage" {
    parts = [{"id": 1, "name": "a"}, {"id": 2, "name": "b"}, {"id": 3, "name": "c"}, {"id": 4, "name": "d"}];
    refs = [{"parent_id": 1, "reference_id": 2}, {"parent_id": 1, "reference_id": 3}, {"parent_id": 2, "reference_id": 4}, {"parent_id": 3, "reference_id": 4}];
    rows = traverse_hierarchy(parts, refs, [1]);
    pids: list[int] = [];
    for r in rows {
        pids.append(r["PartId"]);
    }
    assert sorted(pids) == [1, 2, 3, 4];;
}

test "unknown_anchor_id_tolerance" {
    parts = [{"id": 1, "name": "solo"}];
    refs: list[dict] = [];
    rows = traverse_hierarchy(parts, refs, [99]);
    assert rows == [];;
}

test "rows_carry_join_only_columns" {
    parts = [{"id": 10, "name": "root"}, {"id": 20, "name": "leaf"}];
    refs = [{"parent_id": 10, "reference_id": 20}];
    rows = traverse_hierarchy(parts, refs, [10]);
    assert len(rows) == 2;;
    cols: list[str] = [];
    for c in REQUIRED_COLS {
        cols.append(c);
    }
    for r in rows {
        for c in cols {
            assert c in r;;
        }
    }
}
