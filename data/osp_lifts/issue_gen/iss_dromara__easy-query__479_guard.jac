# dromara/easy-query#479 — asTreeCte extra column (root_id) via recursive tree walk.

node RowNode {
    has nid: str;
    has parent_key: str = "";
    has root_id: str = "";
}

edge ParentOf {}

walker RootAnnotator {
    has claimed: dict[str, bool] = {};
    has root_val: str = "";
    has out_rows: list[dict] = [];

    can seed with RowNode entry {
        if here.nid in self.claimed {
            skip;
        }
        self.claimed[here.nid] = True;
        here.root_id = self.root_val;
        row: dict = {};
        row["id"] = here.nid;
        if here.parent_key == "" {
            row["parent_id"] = None;
        } else {
            row["parent_id"] = here.parent_key;
        }
        row["root_id"] = here.root_id;
        self.out_rows.append(row);
        print("annotate " + here.nid + " root=" + self.root_val);
        kids: list[RowNode] = [here ->:ParentOf:->][?:RowNode];
        kid_nids: list[str] = [];
        for kid in kids {
            kid_nids.append(kid.nid);
        }
        kid_nids = sorted(kid_nids);
        ordered: list[RowNode] = [];
        for kn in kid_nids {
            for kid in kids {
                if kid.nid == kn {
                    ordered.append(kid);
                    break;
                }
            }
        }
        for kid in ordered {
            visit :0: kid;
        }
    }
}

def sort_rows(rows: list[dict]) -> list[dict] {
    ids: list[str] = [];
    for r in rows {
        ids.append(r["id"] as str);
    }
    ids = sorted(ids);
    out: list[dict] = [];
    for sid in ids {
        for r in rows {
            if (r["id"] as str) == sid {
                out.append(r);
                break;
            }
        }
    }
    return out;
}

def sort_roots(nodes: list[RowNode]) -> list[RowNode] {
    nids: list[str] = [];
    for n in nodes {
        nids.append(n.nid);
    }
    nids = sorted(nids);
    out: list[RowNode] = [];
    for nid in nids {
        for n in nodes {
            if n.nid == nid {
                out.append(n);
                break;
            }
        }
    }
    return out;
}

def as_tree_cte(records: list[dict]) -> list[dict] {
    by_id: dict[str, RowNode] = {};
    roots: list[RowNode] = [];
    for rec in records {
        nid: str = rec["id"] as str;
        pid: str = "";
        if "parent_id" in rec {
            if rec["parent_id"] is not None {
                pid = rec["parent_id"] as str;
            }
        }
        nd = RowNode(nid=nid, parent_key=pid);
        by_id[nid] = nd;
        root ++> nd;
    }
    for rec in records {
        nid: str = rec["id"] as str;
        pid: str = "";
        if "parent_id" in rec {
            if rec["parent_id"] is not None {
                pid = rec["parent_id"] as str;
            }
        }
        if pid != "" {
            if pid in by_id {
                par = by_id[pid];
                ch = by_id[nid];
                par +>:ParentOf:+> ch;
            } else {
                roots.append(by_id[nid]);
            }
        } else {
            roots.append(by_id[nid]);
        }
    }
    roots = sort_roots(roots);
    all_out: list[dict] = [];
    for r in roots {
        w = r spawn RootAnnotator(root_val=r.nid, claimed={}, out_rows=[]);
        print("seed walk " + r.nid);
        for row in w.out_rows {
            all_out.append(row);
        }
    }
    return sort_rows(all_out);
}

test "linear_tree_root_id" {
    recs: list[dict] = [];
    recs.append({"id": "a"});
    recs.append({"id": "b", "parent_id": "a"});
    got = as_tree_cte(recs);
    assert len(got) == 2;;
    assert (got[0]["id"] as str) == "a";;
    assert (got[0]["root_id"] as str) == "a";;
    assert (got[1]["id"] as str) == "b";;
    assert (got[1]["root_id"] as str) == "a";;
}

test "multi_root_sorted" {
    recs: list[dict] = [];
    recs.append({"id": "z"});
    recs.append({"id": "a"});
    recs.append({"id": "b", "parent_id": "a"});
    got = as_tree_cte(recs);
    assert len(got) == 3;;
    assert (got[0]["id"] as str) == "a";;
    assert (got[1]["id"] as str) == "b";;
    assert (got[2]["id"] as str) == "z";;
    assert (got[0]["root_id"] as str) == "a";;
    assert (got[2]["root_id"] as str) == "z";;
}

test "missing_parent_becomes_root" {
    recs: list[dict] = [];
    recs.append({"id": "solo", "parent_id": "ghost"});
    got = as_tree_cte(recs);
    assert len(got) == 1;;
    assert (got[0]["id"] as str) == "solo";;
    assert (got[0]["root_id"] as str) == "solo";;
    assert got[0]["parent_id"] is None;;
}

test "diamond_revisit_claim_skip_single_row" {
    r = RowNode(nid="r");
    m = RowNode(nid="m", parent_key="r");
    x = RowNode(nid="x", parent_key="r");
    d = RowNode(nid="d", parent_key="m");
    root ++> r;
    root ++> m;
    root ++> x;
    root ++> d;
    r +>:ParentOf:+> m;
    r +>:ParentOf:+> x;
    m +>:ParentOf:+> d;
    x +>:ParentOf:+> d;
    w = r spawn RootAnnotator(root_val="r", claimed={}, out_rows=[]);
    print("diamond probe");
    got = sort_rows(w.out_rows);
    assert len(got) == 4;;
    d_count: int = 0;
    for row in got {
        if (row["id"] as str) == "d" {
            d_count = d_count + 1;
        }
    }
    assert d_count == 1;;
    assert (got[0]["id"] as str) == "d";;
    assert (got[0]["root_id"] as str) == "r";;
    assert (got[3]["id"] as str) == "x";;
}

test "parent_id_none_on_roots" {
    recs: list[dict] = [];
    recs.append({"id": "r1", "parent_id": None});
    recs.append({"id": "c1", "parent_id": "r1"});
    got = as_tree_cte(recs);
    assert len(got) == 2;;
    assert got[0]["parent_id"] is None;;
    assert (got[1]["parent_id"] as str) == "r1";;
}
