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
