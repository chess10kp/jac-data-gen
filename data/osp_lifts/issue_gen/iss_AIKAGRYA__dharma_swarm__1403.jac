node Region {
    has name: str;
    has rid: str;
    has owner_id: str = "";
    has freshness_window_ms: int = 5000;
    has last_report_ms: int = -1;
    has payload: str = "";
}

node OrganismRoot {
    has rid: str;
}

edge Contains {}

walker FindRegion {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has found: bool = False;
    has found_owner: str = "";
    has found_window: int = 0;
    has found_last: int = -1;
    has found_payload: str = "";
    can find_root with OrganismRoot entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        print("find root");
        for ch in [here ->:Contains:->][?:Region] {
            visit :0: [ch];
        }
    }
    can find_region with Region entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        print("find region");
        if here.name == self.target {
            self.found = True;
            self.found_owner = here.owner_id;
            self.found_window = here.freshness_window_ms;
            self.found_last = here.last_report_ms;
            self.found_payload = here.payload;
        }
    }
}

walker Demo {
    has claimed: dict[str, bool] = {};
    can demo_root with OrganismRoot entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        print("demo root");
        for ch in [here ->:Contains:->][?:Region] {
            visit :0: [ch];
        }
    }
    can demo_region with Region entry {
        if here.rid in self.claimed { skip; }
        self.claimed[here.rid] = True;
        print("demo region");
    }
}

def digest_of(payload: str) -> str {
    return str(len(payload)) + ":" + payload;
}

def build_organism_graph() -> OrganismRoot {
    org = OrganismRoot(rid="org-root");
    r1 = Region(name="MissionControl", rid="r-mc");
    r2 = Region(name="TaskBoard", rid="r-tb");
    r3 = Region(name="RuntimeState", rid="r-rs");
    r4 = Region(name="Swarm", rid="r-sw");
    r5 = Region(name="A2A", rid="r-a2a");
    r6 = Region(name="evolution", rid="r-ev");
    org +>:Contains:+> r1;
    org +>:Contains:+> r2;
    org +>:Contains:+> r3;
    org +>:Contains:+> r4;
    org +>:Contains:+> r5;
    org +>:Contains:+> r6;
    return org;
}

def bind_owner(graph_root: OrganismRoot, region: str, owner: str, freshness_window_ms: int) -> bool {
    w = graph_root spawn FindRegion(target=region);
    if w.found == False {
        return False;
    }
    for ch in [graph_root ->:Contains:->][?:Region] {
        if ch.name == region {
            ch.owner_id = owner;
            ch.freshness_window_ms = freshness_window_ms;
            return True;
        }
    }
    return False;
}

def record_report(graph_root: OrganismRoot, region: str, timestamp_ms: int, payload: str) -> bool {
    w = graph_root spawn FindRegion(target=region);
    if w.found == False {
        return False;
    }
    for ch in [graph_root ->:Contains:->][?:Region] {
        if ch.name == region {
            ch.last_report_ms = timestamp_ms;
            ch.payload = payload;
            return True;
        }
    }
    return False;
}

def adapter_read(graph_root: OrganismRoot, region: str, owner: str, seq: int, correlation_id: str, causation_id: str, parent_id: str) -> dict[str, str] {
    w = graph_root spawn FindRegion(target=region);
    env: dict[str, str] = {};
    env["schema_version"] = "2.0";
    env["correlation_id"] = correlation_id;
    env["causation_id"] = causation_id;
    env["parent_id"] = parent_id;
    env["sequence"] = str(seq);
    env["region"] = region;
    env["owner"] = owner;
    if w.found == False {
        env["freshness"] = "unknown";
        env["availability"] = "unknown";
        env["digest"] = digest_of("");
        env["payload"] = "";
        return env;
    }
    pl: str = w.found_payload;
    env["payload"] = pl;
    env["digest"] = digest_of(pl);
    if pl == "partial" {
        env["freshness"] = "partial";
        env["availability"] = "degraded";
        return env;
    }
    if w.found_last == -1 {
        env["freshness"] = "unavailable";
        env["availability"] = "unavailable";
        return env;
    }
    cur: int = 10000;
    if cur - w.found_last > w.found_window {
        env["freshness"] = "stale";
        env["availability"] = "stale";
        return env;
    }
    env["freshness"] = "fresh";
    env["availability"] = "ok";
    return env;
}

with entry {
    org = build_organism_graph();
    d = root spawn Demo(claimed={});
    print("organism ready");
}
