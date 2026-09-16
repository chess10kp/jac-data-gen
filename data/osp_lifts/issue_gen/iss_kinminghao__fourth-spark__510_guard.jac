"""kinminghao/fourth-spark#510 — buildIssueContext ancestor chain OSP lift."""

glob MAX_ANCESTOR_DEPTH = 10;

node Issue {
    has cid: str;
    has title: str;
    has parent_id: str = "";
}

edge Parent {}

node IssueCatalog {
    has nodes: dict[str, Issue] = {};
}

walker AncestorCollector {
    has claimed: dict[str, bool] = {};
    has chain: list[dict] = [];

    can climb with Issue entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        if len(self.chain) >= MAX_ANCESTOR_DEPTH {
            disengage;
        }
        row: dict = {};
        row["id"] = here.cid;
        row["title"] = here.title;
        row["parent_id"] = here.parent_id;
        self.chain.append(row);
        ups: list[Issue] = [here ->:Parent:->][?:Issue];
        if ups {
            visit :0: [ups[0]];
        } else {
            disengage;
        }
    }
}

def materialize_issue_graph(issue_by_id: dict) -> IssueCatalog {
    graph_root: node = root;
    catalog = IssueCatalog(nodes={});
    graph_root ++> catalog;
    index: dict[str, Issue] = {};
    keys: list[str] = sorted(issue_by_id.keys());
    for cid in keys {
        rec = issue_by_id[cid] as dict;
        tit: str = rec["title"] as str;
        pid: str = "";
        if "parent_id" in rec {
            pid = rec["parent_id"] as str;
        }
        nd = Issue(cid=cid, title=tit, parent_id=pid);
        graph_root ++> nd;
        index[cid] = nd;
        catalog.nodes[cid] = nd;
    }
    for cid in keys {
        rec = issue_by_id[cid] as dict;
        pid: str = "";
        if "parent_id" in rec {
            pid = rec["parent_id"] as str;
        }
        if pid != "" and pid in index {
            ch = index[cid];
            par = index[pid];
            ch +>:Parent:+> par;
        }
    }
    return catalog;
}

def build_issue_context(issue_id: str, issue_by_id: dict) -> list[dict] {
    empty: list[dict] = [];
    if issue_id not in issue_by_id {
        return empty;
    }
    catalog = materialize_issue_graph(issue_by_id);
    start = catalog.nodes[issue_id];
    aw = start spawn AncestorCollector(claimed={});
    print({"issue_id": issue_id, "context_len": len(aw.chain), "chain": aw.chain});
    return aw.chain;
}

test "unknown_issue_returns_empty" {
    store: dict = {};
    got = build_issue_context("missing", store);
    assert len(got) == 0;
}

test "linear_chain_child_to_root_order" {
    store: dict = {};
    r1: dict = {};
    r1["title"] = "root";
    r1["parent_id"] = "";
    store["i1"] = r1;
    r2: dict = {};
    r2["title"] = "mid";
    r2["parent_id"] = "i1";
    store["i2"] = r2;
    r3: dict = {};
    r3["title"] = "leaf";
    r3["parent_id"] = "i2";
    store["i3"] = r3;
    got = build_issue_context("i3", store);
    ids: list[str] = [];
    for row in got {
        ids.append(row["id"] as str);
    }
    assert ids == ["i3", "i2", "i1"];
}

test "cycle_claim_map_skips_revisit" {
    store: dict = {};
    ra: dict = {};
    ra["title"] = "A";
    ra["parent_id"] = "b";
    store["a"] = ra;
    rb: dict = {};
    rb["title"] = "B";
    rb["parent_id"] = "a";
    store["b"] = rb;
    got = build_issue_context("a", store);
    assert len(got) == 2;
}

test "max_depth_truncates_at_ten" {
    store: dict = {};
    i: int = 0;
    while i < 12 {
        cid: str = "n" + str(i);
        pid: str = "";
        if i > 0 {
            pid = "n" + str(i - 1);
        }
        row: dict = {};
        row["title"] = cid;
        row["parent_id"] = pid;
        store[cid] = row;
        i += 1;
    }
    got = build_issue_context("n11", store);
    assert len(got) == 10;
}

test "missing_parent_stops_after_known_issue" {
    store: dict = {};
    lone: dict = {};
    lone["title"] = "solo";
    lone["parent_id"] = "ghost";
    store["only"] = lone;
    got = build_issue_context("only", store);
    assert len(got) == 1;
    assert got[0]["id"] == "only";
}

test "diamond_revisit_adversarial_insert_order" {
    store: dict = {};
    rd: dict = {};
    rd["title"] = "D";
    rd["parent_id"] = "b";
    store["d"] = rd;
    rb: dict = {};
    rb["title"] = "B";
    rb["parent_id"] = "a";
    store["b"] = rb;
    rc: dict = {};
    rc["title"] = "C";
    rc["parent_id"] = "a";
    store["c"] = rc;
    ra: dict = {};
    ra["title"] = "A";
    ra["parent_id"] = "";
    store["a"] = ra;
    got = build_issue_context("d", store);
    ids: list[str] = [];
    for row in got {
        ids.append(row["id"] as str);
    }
    assert ids == ["d", "b", "a"];
}
