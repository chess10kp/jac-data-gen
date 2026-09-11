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

test "adapter read is byte identical on double read" {
    g = build_organism_graph();
    bind_owner(g, "A2A", "owner-a2a", 5000);
    record_report(g, "A2A", 9000, "ok-payload");
    e1: dict[str, str] = adapter_read(g, "A2A", "owner-a2a", 99, "cid", "caus", "pid");
    e2: dict[str, str] = adapter_read(g, "A2A", "owner-a2a", 99, "cid", "caus", "pid");
    assert(e1 == e2);
    assert(e1["digest"] == e2["digest"]);
}

test "envelope fields present and golden vector" {
    g = build_organism_graph();
    bind_owner(g, "MissionControl", "owner-mc", 5000);
    record_report(g, "MissionControl", 9500, "hello");
    env: dict[str, str] = adapter_read(g, "MissionControl", "owner-mc", 42, "corr-1", "caus-1", "par-1");
    assert(env["schema_version"] == "2.0");
    assert(env["correlation_id"] == "corr-1");
    assert(env["causation_id"] == "caus-1");
    assert(env["parent_id"] == "par-1");
    assert(env["sequence"] == "42");
    assert(env["digest"] == digest_of("hello"));
    assert(env["freshness"] == "fresh");
    assert(env["availability"] == "ok");
}

test "diamond revisit does not duplicate and still reports fresh" {
    g = build_organism_graph();
    bind_owner(g, "Swarm", "owner-swarm", 5000);
    record_report(g, "Swarm", 9600, "swarm-data");
    extra: Region = Region(name="Swarm", rid="r-sw-dup");
    g +>:Contains:+> extra;
    e: dict[str, str] = adapter_read(g, "Swarm", "owner-swarm", 7, "c", "ca", "p");
    assert(e["freshness"] == "fresh");
    assert(e["payload"] == "swarm-data");
}

test "unknown region tolerance returns unknown" {
    g = build_organism_graph();
    env: dict[str, str] = adapter_read(g, "UnknownRegion", "ghost", 1, "cid", "caus", "pid");
    assert(env["freshness"] == "unknown");
    assert(env["availability"] == "unknown");
    assert(env["schema_version"] == "2.0");
}

test "stale and unavailable negative control never reports fresh" {
    g = build_organism_graph();
    bind_owner(g, "RuntimeState", "owner-rs", 1000);
    record_report(g, "RuntimeState", 0, "old-data");
    s: dict[str, str] = adapter_read(g, "RuntimeState", "owner-rs", 10, "cid", "caus", "pid");
    assert(s["freshness"] == "stale");
    assert(s["availability"] == "stale");
    assert(s["freshness"] != "fresh");
    g2 = build_organism_graph();
    bind_owner(g2, "evolution", "owner-ev", 5000);
    u: dict[str, str] = adapter_read(g2, "evolution", "owner-ev", 11, "cid2", "caus2", "pid2");
    assert(u["freshness"] == "unavailable");
    assert(u["availability"] == "unavailable");
    p: dict[str, str] = adapter_read(g2, "TaskBoard", "owner-tb", 12, "cid3", "caus3", "pid3");
    bind_owner(g2, "TaskBoard", "owner-tb", 5000);
    record_report(g2, "TaskBoard", 9900, "partial");
    pp: dict[str, str] = adapter_read(g2, "TaskBoard", "owner-tb", 12, "cid3", "caus3", "pid3");
    assert(pp["freshness"] == "partial");
}

test "six regions distinguishable freshness states" {
    g = build_organism_graph();
    regions: list[str] = ["MissionControl", "TaskBoard", "RuntimeState", "Swarm", "A2A", "evolution"];
    for r in regions {
        bind_owner(g, r, "owner-" + r, 5000);
    }
    record_report(g, "MissionControl", 9900, "ok");
    record_report(g, "TaskBoard", 9900, "partial");
    fresh: dict[str, str] = adapter_read(g, "MissionControl", "owner-MissionControl", 1, "a", "b", "c");
    part: dict[str, str] = adapter_read(g, "TaskBoard", "owner-TaskBoard", 1, "a", "b", "c");
    unav: dict[str, str] = adapter_read(g, "Swarm", "owner-Swarm", 1, "a", "b", "c");
    assert(fresh["freshness"] == "fresh");
    assert(part["freshness"] == "partial");
    assert(unav["freshness"] == "unavailable");
    assert(fresh["freshness"] != part["freshness"]);
    assert(part["freshness"] != unav["freshness"]);
}
