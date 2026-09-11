"""acryldata/mcp-server-datahub#152 — MCP lineage tools inherit per-call telemetry stall."""

glob TELEMETRY_STALL_MS = 54000;
glob FAST_QUERY_MS = 90;

node Dataset {
    has urn: str;
    has layer: str;
    has updated_at: int;
    has fields: list[str] = [];
}

edge LineageFlow {}

obj LineageRegistry {
    has datasets: dict[str, Dataset] = {};
    has telemetry_enabled: bool = True;
    has call_count: int = 0;
}

walker UpstreamReach {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with Dataset entry {
        if here.urn == self.origin {
            visit [<-:LineageFlow:<-][?:Dataset];
            skip;
        }
        if here.urn in self.claimed { skip; }
        self.claimed[here.urn] = True;
        self.found.append(here.urn);
        visit [<-:LineageFlow:<-][?:Dataset];
    }
}

walker DownstreamReach {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with Dataset entry {
        if here.urn == self.origin {
            visit [->:LineageFlow:->][?:Dataset];
            skip;
        }
        if here.urn in self.claimed { skip; }
        self.claimed[here.urn] = True;
        self.found.append(here.urn);
        visit [->:LineageFlow:->][?:Dataset];
    }
}

walker LineagePathWalk {
    has trail: list[str] = [];
    has on_path: dict[str, bool] = {};
    has paths: list[list[str]] = [];
    has target: str = "";
    has max_depth: int = 12;

    can step with Dataset entry {
        if here.urn in self.on_path { skip; }
        nt: list[str] = [];
        for x in self.trail { nt.append(x); }
        nt.append(here.urn);
        nop: dict[str, bool] = {**self.on_path, here.urn: True};
        if len(nt) > self.max_depth { skip; }
        if here.urn == self.target {
            row: list[str] = [];
            for x in nt { row.append(x); }
            self.paths.append(row);
            skip;
        }
        ups = [here <-:LineageFlow:<-][?:Dataset];
        nms: list[str] = [];
        for n in ups { nms.append(n.urn); }
        for nm in sorted(nms) {
            for n in ups {
                if n.urn == nm {
                    n spawn LineagePathWalk(
                        trail=nt,
                        on_path=nop,
                        paths=self.paths,
                        target=self.target,
                        max_depth=self.max_depth,
                    );
                }
            }
        }
    }
}

def _account_call(reg: LineageRegistry) -> int {
    reg.call_count += 1;
    if reg.telemetry_enabled {
        return TELEMETRY_STALL_MS + FAST_QUERY_MS;
    }
    return FAST_QUERY_MS;
}

def _lineage_paths(
    reg: LineageRegistry,
    source: str,
    target: str,
    *,
    max_depth: int,
) -> list[list[str]] {
    if not (source in reg.datasets) or not (target in reg.datasets) { return []; }
    nd = reg.datasets[source];
    w = nd spawn LineagePathWalk(trail=[], on_path={}, paths=[], target=target, max_depth=max_depth);
    out: list[list[str]] = [];
    for pth in w.paths {
        row: list[str] = [];
        for x in pth { row.append(x); }
        out.append(row);
    }
    return sorted(out);
}

def load_lineage_registry(
    datasets: list[tuple[str, str, int]],
    edges: list[tuple[str, str]],
    schema: list[tuple[str, list[str]]],
    *,
    telemetry_enabled: bool = True,
) -> LineageRegistry {
    reg = LineageRegistry(telemetry_enabled=telemetry_enabled);
    for (urn, layer, updated_at) in datasets {
        nd = Dataset(urn=urn, layer=layer, updated_at=updated_at);
        root ++> nd;
        reg.datasets[urn] = nd;
    }
    for (src, tgt) in edges {
        if not (src in reg.datasets) or not (tgt in reg.datasets) { continue; }
        reg.datasets[src] +>:LineageFlow:+> reg.datasets[tgt];
    }
    for (urn, flds) in schema {
        if urn in reg.datasets {
            reg.datasets[urn].fields = sorted(flds);
        }
    }
    return reg;
}

def get_lineage(
    reg: LineageRegistry,
    urn: str,
    direction: str = "upstream",
) -> list[str] {
    _account_call(reg);
    if not (urn in reg.datasets) { return []; }
    nd = reg.datasets[urn];
    if direction == "upstream" {
        uw = nd spawn UpstreamReach(claimed={}, found=[], origin=urn);
        return sorted(uw.found);
    }
    dw = nd spawn DownstreamReach(claimed={}, found=[], origin=urn);
    return sorted(dw.found);
}

def list_schema_fields(reg: LineageRegistry, urn: str) -> list[str] {
    _account_call(reg);
    if not (urn in reg.datasets) { return []; }
    return list(reg.datasets[urn].fields);
}

def get_lineage_paths_between(
    reg: LineageRegistry,
    source: str,
    target: str,
    *,
    max_depth: int = 12,
) -> list[list[str]] {
    _account_call(reg);
    return _lineage_paths(reg, source, target, max_depth=max_depth);
}

def per_call_latency_ms(reg: LineageRegistry, tool: str) -> int {
    return _account_call(reg);
}

def bulk_paths_stall_ms(
    reg: LineageRegistry,
    pairs: list[tuple[str, str]],
) -> int {
    total = 0;
    for (src, tgt) in pairs {
        total += _account_call(reg);
        _lineage_paths(reg, src, tgt, max_depth=12);
    }
    return total;
}
