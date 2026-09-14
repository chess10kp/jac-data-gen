# PROGRAM iss_ShaistaShabbir-prog__ETL_Pipeline__22.jac

node PipelineState {
    has cid: str;
    has throughput: int = 0;
}

node DataAsset {
    has cid: str;
    has label: str;
    has rows: int = 0;
    has quality: str = "passed";
}

edge Contains {}
edge FlowsTo {}

walker LineageWalker {
    has claimed: dict[str, bool] = {};
    has labels: list[str] = [];

    can collect_state with PipelineState entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        for asset in [here ->:Contains:->][?:DataAsset] {
            visit :0: [asset];
        }
    }

    can collect_asset with DataAsset entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.labels.append(here.label);
        print(here.label);
        for asset in [here ->:FlowsTo:->][?:DataAsset] {
            visit :0: [asset];
        }
    }
}

walker QualityWalker {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has found: str = "unknown";
    has statuses: dict[str, str] = {};

    can inspect_state with PipelineState entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        for asset in [here ->:Contains:->][?:DataAsset] {
            visit :0: [asset];
        }
    }

    can inspect_asset with DataAsset entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.statuses[here.cid] = here.quality;
        if here.cid == self.target {
            self.found = here.quality;
        }
        print(here.cid + ": " + here.quality);
        for asset in [here ->:FlowsTo:->][?:DataAsset] {
            visit :0: [asset];
        }
    }
}

def build_pipeline() -> PipelineState {
    pipeline = PipelineState(cid="etl_pipeline", throughput=250);

    raw = DataAsset(cid="raw_csv", label="Raw CSV", rows=1000);
    extract = DataAsset(cid="extract", label="Extract", rows=1000);
    validate = DataAsset(cid="validate", label="Great Expectations", rows=1000);
    transform = DataAsset(cid="transform", label="Transform", rows=980);
    load = DataAsset(cid="postgres", label="PostgreSQL", rows=980);
    dashboard = DataAsset(cid="dashboard", label="Dashboard", rows=980);

    pipeline +>:Contains:+> raw;
    raw +>:FlowsTo:+> extract;
    extract +>:FlowsTo:+> validate;
    validate +>:FlowsTo:+> transform;
    transform +>:FlowsTo:+> load;
    load +>:FlowsTo:+> dashboard;

    return pipeline;
}

def lineage_report(graph_root: PipelineState) -> list[str] {
    w = graph_root spawn LineageWalker(claimed={});
    return w.labels;
}

def quality_report(graph_root: PipelineState) -> dict[str, str] {
    w = graph_root spawn QualityWalker(claimed={});
    return w.statuses;
}

def quality_badge(quality_map: dict[str, str]) -> str {
    for cid in quality_map {
        if quality_map[cid] != "passed" {
            return "Data Quality: FAILED ❌";
        }
    }
    return "Data Quality: PASSED ✅";
}

def asset_quality(graph_root: PipelineState, cid: str) -> str {
    w = graph_root spawn QualityWalker(claimed={}, target=cid);
    return w.found;
}

def benchmark(graph_root: PipelineState) -> str {
    return str(graph_root.throughput) + " rows/second";
}
