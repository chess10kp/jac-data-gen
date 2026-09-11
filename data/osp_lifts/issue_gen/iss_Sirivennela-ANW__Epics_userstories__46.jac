"""Sirivennela-ANW/Epics_userstories#46 — Data lineage visualization and impact analysis."""

node Dataset {
    has ds_id: str;
    has layer: str;
    has volume: int;
}

edge Feeds: Dataset --> Dataset {
    has rule: str;
    has quality: float;
    has proc_ms: int;
}

obj LineageCatalog {
    has datasets: dict[str, dict] = {};
    has upstream: dict[str, list[str]] = {};
    has downstream: dict[str, list[str]] = {};
    has edge_meta: dict = {};
    has nodes: dict[str, Dataset] = {};
}

walker UpstreamWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with Dataset entry {
        if here.ds_id in self.claimed { skip; }
        self.claimed[here.ds_id] = True;
        if here.ds_id != self.origin { self.found.append(here.ds_id); }
        visit [<-:Feeds:<-][?:Dataset];
    }
}

walker DownstreamWalk {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    has origin: str = "";

    can step with Dataset entry {
        if here.ds_id in self.claimed { skip; }
        self.claimed[here.ds_id] = True;
        if here.ds_id != self.origin { self.found.append(here.ds_id); }
        visit [->:Feeds:->][?:Dataset];
    }
}

walker LineagePathWalk {
    has target: str = "";
    has max_depth: int = 12;
    has trail: list[str] = [];
    has paths: list[list[str]] = [];

    can step with Dataset entry {
        if here.ds_id in self.trail { skip; }
        nt: list[str] = [];
        for x in self.trail { nt.append(x); }
        nt.append(here.ds_id);
        if here.ds_id == self.target {
            row: list[str] = [];
            for x in nt { row.append(x); }
            self.paths.append(row);
            skip;
        }
        if len(nt) >= self.max_depth { skip; }
        ups = [here <-:Feeds:<-][?:Dataset];
        nms: list[str] = [];
        for u in ups { nms.append(u.ds_id); }
        for nm in sorted(nms) {
            for u in ups {
                if u.ds_id == nm {
                    u spawn LineagePathWalk(
                        target=self.target,
                        max_depth=self.max_depth,
                        trail=nt,
                        paths=self.paths,
                    );
                }
            }
        }
    }
}

def load_lineage_catalog(
    datasets: list[tuple[str, str, int]],
    transforms: list[tuple[str, str, str, float, int]],
) -> LineageCatalog {
    cat = LineageCatalog();
    for (ds_id, layer, volume) in datasets {
        cat.datasets[ds_id] = {"layer": layer, "volume": volume};
        cat.upstream[ds_id] = [];
        cat.downstream[ds_id] = [];
        nd = Dataset(ds_id=ds_id, layer=layer, volume=volume);
        root ++> nd;
        cat.nodes[ds_id] = nd;
    }
    for (src, tgt, rule, quality, proc_ms) in transforms {
        if src not in cat.datasets or tgt not in cat.datasets { continue; }
        if src not in cat.upstream[tgt] {
            cat.upstream[tgt].append(src);
        }
        if tgt not in cat.downstream[src] {
            cat.downstream[src].append(tgt);
        }
        cat.edge_meta[(src, tgt)] = {
            "rule": rule,
            "quality": quality,
            "proc_ms": proc_ms,
        };
        s_raw = cat.nodes.get(src, None);
        t_raw = cat.nodes.get(tgt, None);
        if s_raw is not None and t_raw is not None {
            s = s_raw as Dataset;
            t = t_raw as Dataset;
            feeds = [s ->:Feeds:-> t];
            if len(feeds) == 0 {
                s +>:Feeds(rule=rule, quality=quality, proc_ms=proc_ms):+> t;
            }
        }
    }
    for ds_id in cat.upstream {
        cat.upstream[ds_id] = sorted(cat.upstream[ds_id]);
    }
    for ds_id in cat.downstream {
        cat.downstream[ds_id] = sorted(cat.downstream[ds_id]);
    }
    return cat;
}

def origin_lineage(cat: LineageCatalog, dataset_id: str) -> list[str] {
    if dataset_id not in cat.datasets { return []; }
    raw = cat.nodes.get(dataset_id, None);
    if raw is None { return []; }
    nd = raw as Dataset;
    w = nd spawn UpstreamWalk(claimed={}, found=[], origin=dataset_id);
    return sorted(w.found);
}

def impact_lineage(cat: LineageCatalog, dataset_id: str) -> list[str] {
    if dataset_id not in cat.datasets { return []; }
    raw = cat.nodes.get(dataset_id, None);
    if raw is None { return []; }
    nd = raw as Dataset;
    w = nd spawn DownstreamWalk(claimed={}, found=[], origin=dataset_id);
    return sorted(w.found);
}

def lineage_paths(
    cat: LineageCatalog,
    source: str,
    target: str,
    *,
    max_depth: int = 12,
) -> list[list[str]] {
    if source not in cat.datasets or target not in cat.datasets { return []; }
    raw = cat.nodes.get(source, None);
    if raw is None { return []; }
    nd = raw as Dataset;
    w = nd spawn LineagePathWalk(
        target=target,
        max_depth=max_depth,
        trail=[],
        paths=[],
    );
    out: list[list[str]] = [];
    for p in w.paths {
        row: list[str] = [];
        for x in p { row.append(x); }
        out.append(row);
    }
    return sorted(out);
}

def transformation_rules(cat: LineageCatalog, dataset_id: str) -> list[str] {
    if dataset_id not in cat.datasets { return []; }
    rules: list[str] = [];
    for src in cat.upstream.get(dataset_id, []) {
        meta = cat.edge_meta.get((src, dataset_id), None);
        if meta is not None {
            rules.append(str(meta["rule"]));
        }
    }
    return sorted(rules);
}

def downstream_volume(cat: LineageCatalog, dataset_id: str) -> int {
    total = 0;
    for ds_id in impact_lineage(cat, dataset_id) {
        total += int(cat.datasets[ds_id]["volume"]);
    }
    return total;
}
