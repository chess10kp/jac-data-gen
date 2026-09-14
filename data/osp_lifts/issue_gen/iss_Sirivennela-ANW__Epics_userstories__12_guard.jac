"""Sirivennela-ANW/Epics_userstories#12 — data lineage and impact analysis."""

node Dataset {
    has cid: str;
    has system: str;
    has owner: str;
    has records: int = 0;
    has dashboards: int = 0;
    has contaminated: bool = False;
}

edge Flows {}

obj Pipeline {
    has source: Dataset;
    has dashboard: Dataset;
}

walker LineageWalker {
    has claimed: dict[str, bool] = {};
    has names: list[str] = [];

    can step with Dataset entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.names.append(here.cid);
        print(here.cid);

        kids: list[Dataset] = [];
        for kid in [here ->:Flows:->][?:Dataset] {
            kids.append(kid);
        }
        visit :0: [kids];
    }
}

walker DagWalker {
    has claimed: dict[str, bool] = {};
    has edges: list[str] = [];

    can step with Dataset entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);

        kids: list[Dataset] = [];
        for kid in [here ->:Flows:->][?:Dataset] {
            self.edges.append(here.cid + "->" + kid.cid);
            kids.append(kid);
        }
        visit :0: [kids];
    }
}

walker ReachWalker {
    has target: str;
    has hit: bool = False;
    has claimed: dict[str, bool] = {};
    has seen: list[str] = [];
    has nodes: dict[str, Dataset] = {};

    can step with Dataset entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.seen.append(here.cid);
        self.nodes[here.cid] = here;
        print(here.cid);

        if here.cid == self.target {
            self.hit = True;
        }

        kids: list[Dataset] = [];
        for kid in [here ->:Flows:->][?:Dataset] {
            kids.append(kid);
        }
        visit :0: [kids];
    }
}

walker ImpactWalker {
    has claimed: dict[str, bool] = {};
    has records: int = 0;
    has systems: dict[str, bool] = {};
    has dashboards: int = 0;
    has owners: dict[str, bool] = {};

    can step with Dataset entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);

        if here.contaminated {
            self.records += here.records;
            self.dashboards += here.dashboards;
            self.systems[here.system] = True;
            self.owners[here.owner] = True;
        }

        kids: list[Dataset] = [];
        for kid in [here ->:Flows:->][?:Dataset] {
            kids.append(kid);
        }
        visit :0: [kids];
    }
}

def build_pkg() -> Pipeline {
    source = Dataset(
        cid="source",
        system="warehouse",
        owner="steward@data",
        records=15,
        contaminated=True
    );
    clean = Dataset(cid="clean", system="warehouse", owner="steward@data");
    enrich = Dataset(cid="enrich", system="analytics", owner="platform@data");
    shared = Dataset(cid="shared", system="analytics", owner="platform@data");
    dashboard = Dataset(
        cid="dashboard",
        system="analytics",
        owner="bi@data",
        dashboards=6
    );

    source +>:Flows:+> enrich;
    source +>:Flows:+> clean;
    clean +>:Flows:+> shared;
    enrich +>:Flows:+> shared;
    shared +>:Flows:+> dashboard;

    highlight_path(source, "dashboard");
    return Pipeline(source=source, dashboard=dashboard);
}

def walk(source: Dataset) -> list[str] {
    w = source spawn LineageWalker();
    return sorted(w.names);
}

def lineage(source: Dataset) -> list[str] {
    return walk(source);
}

def workflow_dag(source: Dataset) -> list[str] {
    w = source spawn DagWalker();
    return sorted(w.edges);
}

def path_reach(source: Dataset, target_id: str) -> bool {
    w = source spawn ReachWalker(target=target_id);
    return w.hit;
}

def highlight_path(source: Dataset, target_id: str) -> list[str] {
    w = source spawn ReachWalker(target=target_id);
    if w.hit == False {
        return [];
    }

    for cid in w.seen {
        affected = w.nodes[cid];
        affected.contaminated = True;
    }
    return sorted(w.seen);
}

def impact_report(source: Dataset) -> dict[str, int] {
    w = source spawn ImpactWalker();
    result: dict[str, int] = {};
    result["records"] = w.records;
    result["systems"] = len(w.systems);
    result["dashboards"] = w.dashboards;
    return result;
}

def notify_owners(source: Dataset) -> list[str] {
    w = source spawn ImpactWalker();
    return sorted(w.owners);
}

# TESTS

test "diamond revisit is once only" {
    pkg = build_pkg();
    ids = lineage(pkg.source);
    assert (len(ids) == 5);
    assert (sorted(ids) == ["clean", "dashboard", "enrich", "shared", "source"]);
}

test "workflow dag is deterministic" {
    pkg = build_pkg();
    edges = workflow_dag(pkg.source);
    assert (sorted(edges) == [
        "clean->shared",
        "enrich->shared",
        "shared->dashboard",
        "source->clean",
        "source->enrich"
    ]);
}

test "unknown targets are tolerated" {
    pkg = build_pkg();
    assert (path_reach(pkg.source, "missing") == False);
    assert (highlight_path(pkg.source, "missing") == []);
}

test "impact and notifications include affected consumers" {
    pkg = build_pkg();
    impact = impact_report(pkg.source);
    owners = notify_owners(pkg.source);
    assert (pkg.dashboard.contaminated == True);
    assert (impact["records"] == 15);
    assert (impact["systems"] == 2);
    assert (impact["dashboards"] == 6);
    assert (owners == ["bi@data", "steward@data"]);
}
