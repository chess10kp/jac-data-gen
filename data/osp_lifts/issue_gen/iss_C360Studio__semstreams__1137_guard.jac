"""Production GraphRAG epic lineage, partition, reach — C360Studio/semstreams#1137."""

node Issue {
    has iid: str;
    has title: str = "";
    has prefix: str = "";
}

edge ParentOf {}
edge Sequences {}

def build_graph(
    specs: list[dict],
    parent_pairs: list[list[str]],
    seq_pairs: list[list[str]],
) -> Issue {
    anchor = Issue(iid="__anchor__", title="anchor");
    root ++> anchor;
    store: dict[str, Issue] = {};
    for spec in specs {
        iid = spec["iid"] as str;
        title = "";
        if "title" in spec {
            title = spec["title"] as str;
        }
        prefix = "";
        if "prefix" in spec {
            prefix = spec["prefix"] as str;
        }
        nd = Issue(iid=iid, title=title, prefix=prefix);
        store[iid] = nd;
        anchor ++> nd;
    }
    for pair in parent_pairs {
        pid = pair[0] as str;
        cid = pair[1] as str;
        if pid in store and cid in store {
            store[pid] +>:ParentOf:+> store[cid];
        }
    }
    for pair in seq_pairs {
        a = pair[0] as str;
        b = pair[1] as str;
        if a in store and b in store {
            store[a] +>:Sequences:+> store[b];
        }
    }
    return anchor;
}

def gather_issues(anchor: Issue) -> dict[str, Issue] {
    store: dict[str, Issue] = {};
    for nd in [anchor -->][?:Issue] {
        if nd.iid != "__anchor__" {
            store[nd.iid] = nd;
        }
    }
    return store;
}

walker CollectWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can collect with Issue entry {
        if here.iid in self.claimed {
            skip;
        }
        self.claimed[here.iid] = True;
        self.found.append(here.iid);
        print("collect ", here.iid);
        kids: list[Issue] = [here ->:ParentOf:->][?:Issue];
        pending: list[Issue] = [];
        for ch in kids {
            pending.append(ch);
        }
        for ch in pending {
            visit :0: [ch];
        }
    }
}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has goal: str = "";
    has reachable: bool = False;
    can reach with Issue entry {
        if here.iid in self.claimed {
            skip;
        }
        self.claimed[here.iid] = True;
        print("reach ", here.iid);
        if here.iid == self.goal {
            self.reachable = True;
            disengage;
        }
        kids: list[Issue] = [here ->:ParentOf:->][?:Issue];
        nxt: list[Issue] = [];
        for ch in kids {
            nxt.append(ch);
        }
        if len(nxt) > 0 {
            visit nxt;
        } else {
            disengage;
        }
    }
}

walker OrderWalker {
    has claimed: dict[str, bool] = {};
    has ordered: list[str] = [];
    can order with Issue entry {
        if here.iid in self.claimed {
            skip;
        }
        self.claimed[here.iid] = True;
        self.ordered.append(here.iid);
        print("order ", here.iid);
        nxt: list[Issue] = [here ->:Sequences:->][?:Issue];
        front: list[Issue] = [];
        for ch in nxt {
            front.append(ch);
        }
        if len(front) > 0 {
            visit :0: front;
        }
    }
}

def direct_children(
    parent_id: str,
    parent_pairs: list[list[str]],
    specs: list[dict],
) -> list[str] {
    anchor = build_graph(specs, parent_pairs, []);
    store = gather_issues(anchor);
    if parent_id not in store {
        return [];
    }
    out: list[str] = [];
    for ch in [store[parent_id] ->:ParentOf:->][?:Issue] {
        out.append(ch.iid);
    }
    return sorted(out);
}

def closure_ids(
    root_id: str,
    parent_pairs: list[list[str]],
    specs: list[dict],
) -> list[str] {
    anchor = build_graph(specs, parent_pairs, []);
    store = gather_issues(anchor);
    if root_id not in store {
        return [];
    }
    w = store[root_id] spawn CollectWalker(claimed={}, found=[]);
    return sorted(w.found);
}

def path_reachable(
    from_id: str,
    to_id: str,
    parent_pairs: list[list[str]],
    specs: list[dict],
) -> bool {
    anchor = build_graph(specs, parent_pairs, []);
    store = gather_issues(anchor);
    if from_id not in store or to_id not in store {
        return False;
    }
    w = store[from_id] spawn ReachWalker(claimed={}, goal=to_id, reachable=False);
    return w.reachable;
}

def partition_by_prefix(specs: list[dict]) -> dict[str, list[str]] {
    buckets: dict[str, list[str]] = {};
    for spec in specs {
        iid = spec["iid"] as str;
        pfx = "";
        if "prefix" in spec {
            pfx = spec["prefix"] as str;
        }
        if pfx not in buckets {
            buckets[pfx] = [];
        }
        buckets[pfx].append(iid);
    }
    out: dict[str, list[str]] = {};
    for spec in specs {
        pfx = "";
        if "prefix" in spec {
            pfx = spec["prefix"] as str;
        }
        if pfx not in out {
            out[pfx] = sorted(buckets[pfx]);
        }
    }
    return out;
}

def sequence_walk(
    start_id: str,
    parent_pairs: list[list[str]],
    seq_pairs: list[list[str]],
    specs: list[dict],
) -> list[str] {
    anchor = build_graph(specs, parent_pairs, seq_pairs);
    store = gather_issues(anchor);
    if start_id not in store {
        return [];
    }
    w = store[start_id] spawn OrderWalker(claimed={}, ordered=[]);
    return w.ordered;
}

test "diamond_closure_revisit_skipped" {
    specs: list[dict] = [
        {"iid": "1137"},
        {"iid": "606"},
        {"iid": "609"},
        {"iid": "823"},
    ];
    pairs: list[list[str]] = [
        ["1137", "606"],
        ["1137", "609"],
        ["609", "823"],
        ["606", "823"],
        ["606", "609"],
    ];
    got = closure_ids("1137", pairs, specs);
    assert got == ["1137", "606", "609", "823"];
}

test "unknown_root_empty_closure" {
    specs: list[dict] = [{"iid": "606"}];
    got = closure_ids("missing", [], specs);
    assert got == [];
}

test "unknown_target_not_reachable" {
    specs: list[dict] = [{"iid": "606"}, {"iid": "609"}];
    pairs: list[list[str]] = [["606", "609"]];
    assert path_reachable("606", "missing", pairs, specs) == False;
    assert path_reachable("missing", "609", pairs, specs) == False;
}

test "prefix_partition_sorted_buckets" {
    specs: list[dict] = [
        {"iid": "606", "prefix": "partition"},
        {"iid": "823", "prefix": "retrieval"},
        {"iid": "829", "prefix": "retrieval"},
        {"iid": "1117", "prefix": "proof"},
    ];
    got = partition_by_prefix(specs);
    assert got["partition"] == ["606"];
    assert got["retrieval"] == ["823", "829"];
    assert got["proof"] == ["1117"];
}

test "sequence_walk_epic_ordering" {
    specs: list[dict] = [
        {"iid": "606"},
        {"iid": "609"},
        {"iid": "823"},
        {"iid": "1136"},
    ];
    seq: list[list[str]] = [["606", "609"], ["609", "823"], ["823", "1136"]];
    got = sequence_walk("606", [], seq, specs);
    assert got == ["606", "609", "823", "1136"];
}

test "direct_children_sorted" {
    specs: list[dict] = [
        {"iid": "1137"},
        {"iid": "606"},
        {"iid": "823"},
        {"iid": "829"},
    ];
    pairs: list[list[str]] = [
        ["1137", "829"],
        ["1137", "606"],
        ["1137", "823"],
    ];
    got = direct_children("1137", pairs, specs);
    assert got == ["606", "823", "829"];
}
