# PROGRAM iss_ApexChainx__ApexChainx-Backend__311.jac
# Models ApexChainx/ApexChainx-Backend#311.

node Catalog {
    has cid: str;
}

node Outage {
    has cid: str;
    has oid: str;
    has title: str;
    has resolved: bool = False;
}

node SLAResult {
    has cid: str;
    has status: str;
    has latest: bool = True;
}

edge Contains {}
edge Related {}
edge HasSLA {}

walker CollectOutages {
    has claimed: dict[str, bool] = {};
    has found: list[Outage] = [];

    can collect_catalog with Catalog entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("catalog", here.cid);
        for kid in [here ->:Contains:->][?:Outage] {
            visit :0: [kid];
        }
    }

    can collect_outage with Outage entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here);
        print("outage", here.oid);
        for kid in [here ->:Related:->][?:Outage] {
            visit :0: [kid];
        }
    }
}

walker CollectSLA {
    has claimed: dict[str, bool] = {};
    has found: list[SLAResult] = [];

    can collect_outage with Outage entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("sla-source", here.oid);
        for result in [here ->:HasSLA:->][?:SLAResult] {
            visit :0: [result];
        }
    }

    can collect_result with SLAResult entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here);
        print("sla-result", here.status);
    }
}

def find_outage(graph_root: Catalog, outage_id: str) -> list[Outage] {
    w = graph_root spawn CollectOutages(claimed={});
    matches: list[Outage] = [];
    for outage in w.found {
        if outage.oid == outage_id {
            matches.append(outage);
        }
    }
    return matches;
}

def build_graph() -> Catalog {
    return Catalog(cid="catalog");
}

def add_outage(graph_root: Catalog, outage_id: str, title: str) -> bool {
    if len(find_outage(graph_root, outage_id)) > 0 {
        return False;
    }
    outage = Outage(cid="outage:" + outage_id, oid=outage_id, title=title);
    graph_root +>:Contains:+> outage;
    return True;
}

def link_outages(graph_root: Catalog, source_id: str, target_id: str) -> bool {
    sources = find_outage(graph_root, source_id);
    targets = find_outage(graph_root, target_id);
    if len(sources) == 0 || len(targets) == 0 {
        return False;
    }
    sources[0] +>:Related:+> targets[0];
    return True;
}

def recompute_sla(
    graph_root: Catalog, outage_id: str, status: str
) -> bool {
    outages = find_outage(graph_root, outage_id);
    if len(outages) == 0 {
        return False;
    }
    outage = outages[0];
    w = outage spawn CollectSLA(claimed={});
    for result in w.found {
        if result.latest {
            result.latest = False;
        }
    }
    result = SLAResult(
        cid="sla:" + outage_id + ":" + str(len(w.found)),
        status=status,
        latest=True
    );
    outage +>:HasSLA:+> result;
    return True;
}

def resolve_outage(
    graph_root: Catalog, outage_id: str, status: str
) -> bool {
    outages = find_outage(graph_root, outage_id);
    if len(outages) == 0 {
        return False;
    }
    outages[0].resolved = True;
    return recompute_sla(graph_root, outage_id, status);
}

def outage_payload(
    graph_root: Catalog, outage_id: str
) -> dict[str, str | None] {
    payload: dict[str, str | None] = {};
    payload["id"] = outage_id;
    payload["title"] = "";
    payload["resolved"] = "false";
    payload["sla_status"] = None;
    outages = find_outage(graph_root, outage_id);
    if len(outages) == 0 {
        return payload;
    }
    outage = outages[0];
    payload["title"] = outage.title;
    if outage.resolved {
        payload["resolved"] = "true";
    }
    w = outage spawn CollectSLA(claimed={});
    for result in w.found {
        if result.latest {
            payload["sla_status"] = result.status;
        }
    }
    return payload;
}

def export_outages(
    graph_root: Catalog
) -> list[dict[str, str | None]] {
    all_outages = graph_root spawn CollectOutages(claimed={});
    ids: list[str] = [];
    for outage in all_outages.found {
        ids.append(outage.oid);
    }
    rows: list[dict[str, str | None]] = [];
    for outage_id in sorted(ids) {
        rows.append(outage_payload(graph_root, outage_id));
    }
    return rows;
}
