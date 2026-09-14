"""GitHub issue: Sirivennela-ANW/Epics_userstories#59."""

node Dataset {
    has id: str;
    has kind: str = "dataset";
    has records: int = 0;
    has owner: str = "";
    has lineage_root: str = "";
    has contaminated: bool = False;
}

edge Flow {
    has contaminated: bool = False;
}

walker Locate {
    has target: str;
    has claimed: dict[str, bool] = {};
    has matches: list[Dataset] = [];

    can locate with Dataset entry {
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        print(here.id);
        if here.id == self.target {
            self.matches.append(here);
        }
        for kid in [here ->:Flow:->][?:Dataset] {
            visit :0: [kid];
        }
    }
}

walker Audit {
    has claimed: dict[str, bool] = {};
    has stop_id: str = "";
    has started: bool = False;
    has reached: bool = False;
    has found: list[str] = [];
    has owners: list[str] = [];
    has records: int = 0;
    has systems: int = 0;
    has dashboards: int = 0;

    can audit with Dataset entry {
        if here.id in self.claimed { skip; }
        self.claimed[here.id] = True;
        print(here.id);

        if here.id == self.stop_id {
            self.reached = True;
        }
        if self.started {
            self.found.append(here.id);
            self.owners.append(here.owner);
            self.records += here.records;
            if here.kind == "system" {
                self.systems += 1;
            }
            if here.kind == "dashboard" {
                self.dashboards += 1;
            }
        } else {
            self.started = True;
        }

        for kid in [here ->:Flow:->][?:Dataset] {
            visit :0: [kid];
        }
    }
}

def locate(root_node: Dataset, wanted: str) -> Dataset | None {
    w = root_node spawn Locate(target=wanted, claimed={});
    if len(w.matches) == 0 {
        return None;
    }
    return w.matches[0];
}

def build_lineage() -> Dataset {
    source = Dataset(
        id="source_orders",
        kind="source",
        records=1000,
        owner="ingest",
        lineage_root="source_orders",
        contaminated=True
    );
    clean = Dataset(
        id="clean_orders",
        kind="transformation",
        records=1000,
        owner="quality",
        lineage_root="source_orders",
        contaminated=True
    );
    stream = Dataset(
        id="stream_orders",
        kind="transformation",
        records=1000,
        owner="streaming",
        lineage_root="source_orders",
        contaminated=True
    );
    warehouse = Dataset(
        id="warehouse_orders",
        kind="system",
        records=1000,
        owner="analytics",
        lineage_root="source_orders",
        contaminated=True
    );
    dashboard = Dataset(
        id="sales_dashboard",
        kind="dashboard",
        records=1000,
        owner="bi",
        lineage_root="source_orders",
        contaminated=True
    );
    alerts = Dataset(
        id="ops_alerts",
        kind="system",
        records=10,
        owner="ops",
        lineage_root="source_orders",
        contaminated=True
    );

    source +>:Flow:+> clean;
    source +>:Flow:+> stream;
    clean +>:Flow:+> warehouse;
    stream +>:Flow:+> warehouse;
    warehouse +>:Flow:+> dashboard;
    warehouse +>:Flow:+> alerts;
    return source;
}

def downstream_consumers(root_node: Dataset, issue_id: str) -> list[str] {
    result: list[str] = [];
    affected = locate(root_node, issue_id);
    if affected == None {
        return result;
    }
    w = affected spawn Audit(claimed={});
    for item in w.found {
        result.append(item);
    }
    return sorted(result);
}

def contaminated_path(
    root_node: Dataset,
    source_id: str,
    destination_id: str
) -> list[str] {
    result: list[str] = [];
    source = locate(root_node, source_id);
    destination = locate(root_node, destination_id);
    if source == None || destination == None {
        return result;
    }

    w = source spawn Audit(claimed={}, stop_id=destination_id);
    if !w.reached {
        return result;
    }
    result.append(source.id);
    for item in w.found {
        result.append(item);
    }
    return sorted(result);
}

def impact_report(root_node: Dataset, issue_id: str) -> dict[str, int] {
    report: dict[str, int] = {};
    affected = locate(root_node, issue_id);
    if affected == None {
        report["records"] = 0;
        report["systems"] = 0;
        report["dashboards"] = 0;
        report["consumers"] = 0;
        return report;
    }

    w = affected spawn Audit(claimed={});
    report["records"] = w.records;
    report["systems"] = w.systems;
    report["dashboards"] = w.dashboards;
    report["consumers"] = len(w.found);
    return report;
}

def notify_teams(root_node: Dataset, issue_id: str) -> list[str] {
    owners: list[str] = [];
    seen: dict[str, bool] = {};
    affected = locate(root_node, issue_id);
    if affected == None {
        return owners;
    }

    w = affected spawn Audit(claimed={});
    for owner in w.owners {
        if owner not in seen {
            seen[owner] = True;
            owners.append(owner);
        }
    }
    return sorted(owners);
}

def trace_root_cause(root_node: Dataset, issue_id: str) -> str {
    affected = locate(root_node, issue_id);
    if affected == None {
        return "";
    }
    if affected.lineage_root == "" {
        return affected.id;
    }
    return affected.lineage_root;
}

test "diamond traversal claims each node once" {
    graph_root = build_lineage();
    consumers = downstream_consumers(graph_root, "source_orders");
    assert (consumers == [
        "clean_orders",
        "ops_alerts",
        "sales_dashboard",
        "stream_orders",
        "warehouse_orders"
    ]);
    assert (len(consumers) == 5);
}

test "contaminated reach includes both endpoints" {
    graph_root = build_lineage();
    path = contaminated_path(
        graph_root,
        "source_orders",
        "sales_dashboard"
    );
    assert (path == sorted(path));
    assert ("source_orders" in path);
    assert ("sales_dashboard" in path);
    assert (len(path) == 6);
}

test "unknown identifiers are tolerated" {
    graph_root = build_lineage();
    assert (len(downstream_consumers(graph_root, "missing")) == 0);
    assert (len(contaminated_path(
        graph_root,
        "missing",
        "sales_dashboard"
    )) == 0);
    assert (len(contaminated_path(
        graph_root,
        "source_orders",
        "missing"
    )) == 0);
    assert (len(notify_teams(graph_root, "missing")) == 0);
    assert (trace_root_cause(graph_root, "missing") == "");
}

test "impact report and team notifications are deterministic" {
    graph_root = build_lineage();
    report = impact_report(graph_root, "source_orders");
    assert (report["records"] == 4010);
    assert (report["systems"] == 2);
    assert (report["dashboards"] == 1);
    assert (report["consumers"] == 5);
    assert (notify_teams(graph_root, "source_orders") == [
        "analytics",
        "bi",
        "ops",
        "quality",
        "streaming"
    ]);
}

test "leaf and root edge cases" {
    graph_root = build_lineage();
    assert (downstream_consumers(graph_root, "sales_dashboard") == []);
    assert (contaminated_path(
        graph_root,
        "source_orders",
        "source_orders"
    ) == ["source_orders"]);
    assert (trace_root_cause(graph_root, "clean_orders") == "source_orders");
}
