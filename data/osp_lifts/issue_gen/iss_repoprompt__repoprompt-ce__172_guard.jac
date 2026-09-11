"""repoprompt/repoprompt-ce#172 — MCP tool throughput remediation workflow DAG."""

node PlanHub {
    has title: str;
}

node Phase {
    has num: int;
    has name: str;
}

node WorkItem {
    has wid: str;
    has title: str;
    has status: str;
}

edge HubLink {}
edge InPhase {}
edge DependsOn {}

def build_plan() -> PlanHub {
    hub = PlanHub(title="MCP tool throughput remediation");
    root ++> hub;
    p0 = Phase(num=0, name="correctness");
    p1 = Phase(num=1, name="amplification");
    p2 = Phase(num=2, name="contention");
    p3 = Phase(num=3, name="shard_delivery");
    hub +>:HubLink:+> p0;
    hub +>:HubLink:+> p1;
    hub +>:HubLink:+> p2;
    hub +>:HubLink:+> p3;
    wi1 = WorkItem(wid="WI-1", title="watcher crawl", status="landed");
    wi3 = WorkItem(wid="WI-3", title="baseline", status="landed");
    wi7 = WorkItem(wid="WI-7", title="git consolidate", status="landed");
    wi8 = WorkItem(wid="WI-8", title="provider projection", status="landed");
    wi9 = WorkItem(wid="WI-9", title="bounded concurrency", status="landed");
    wi10 = WorkItem(wid="WI-10", title="static classification", status="landed");
    wi11 = WorkItem(wid="WI-11", title="resource capacities", status="landed");
    wi13 = WorkItem(wid="WI-13", title="path index merge", status="landed");
    wi14 = WorkItem(wid="WI-14", title="shared physical-root", status="open");
    wi15 = WorkItem(wid="WI-15", title="publication decouple", status="conditional");
    p0 +>:InPhase:+> wi1;
    p0 +>:InPhase:+> wi3;
    p2 +>:InPhase:+> wi7;
    p2 +>:InPhase:+> wi8;
    p2 +>:InPhase:+> wi9;
    p2 +>:InPhase:+> wi10;
    p2 +>:InPhase:+> wi11;
    p3 +>:InPhase:+> wi13;
    hub +>:HubLink:+> wi14;
    hub +>:HubLink:+> wi15;
    wi7 +>:DependsOn:+> wi3;
    wi8 +>:DependsOn:+> wi7;
    wi9 +>:DependsOn:+> wi7;
    wi10 +>:DependsOn:+> wi8;
    wi10 +>:DependsOn:+> wi9;
    wi11 +>:DependsOn:+> wi10;
    wi13 +>:DependsOn:+> wi11;
    wi14 +>:DependsOn:+> wi13;
    wi15 +>:DependsOn:+> wi14;
    return hub;
}

def item_phase(hub: PlanHub, wid: str) -> int | None {
    for ph in [hub ->:HubLink:->][?:Phase] {
        for wi in [ph ->:InPhase:->][?:WorkItem] {
            if wi.wid == wid {
                return ph.num;
            }
        }
    }
    for wi in [hub ->:HubLink:->][?:WorkItem] {
        if wi.wid == wid {
            return -1;
        }
    }
    return None;
}

def open_items(hub: PlanHub) -> list[str] {
    acc: list[str] = [];
    for ph in [hub ->:HubLink:->][?:Phase] {
        for wi in [ph ->:InPhase:->][?:WorkItem] {
            if wi.status == "open" or wi.status == "conditional" {
                acc.append(wi.wid);
            }
        }
    }
    for wi in [hub ->:HubLink:->][?:WorkItem] {
        if wi.status == "open" or wi.status == "conditional" {
            acc.append(wi.wid);
        }
    }
    return sorted(acc);
}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has start: str = "";
    has active: bool = False;
    has found: list[str] = [];

    can hub_entry with PlanHub entry {
        print(["reach_hub", here.title]);
        nexts: list[object] = [];
        for ph in [here ->:HubLink:->][?:Phase] {
            nexts.append(ph);
        }
        for wi in [here ->:HubLink:->][?:WorkItem] {
            nexts.append(wi);
        }
        visit nexts;
    }

    can phase_entry with Phase entry {
        print(["reach_phase", here.num]);
        kids: list[WorkItem] = [];
        for wi in [here ->:InPhase:->][?:WorkItem] {
            kids.append(wi);
        }
        visit kids;
    }

    can item_entry with WorkItem entry {
        if here.wid == self.start {
            self.active = True;
        }
        if self.active {
            if here.wid in self.claimed {
                skip;
            }
            self.claimed[here.wid] = True;
            self.found.append(here.wid);
            print(["reach_item", here.wid]);
        }
        deps: list[WorkItem] = [];
        for dep in [here <-:DependsOn:<-][?:WorkItem] {
            deps.append(dep);
        }
        visit deps;
    }
}

def reachable_ids(hub: PlanHub, start: str) -> list[str] {
    w = hub spawn ReachWalker(start=start, claimed={}, active=False, found=[]);
    return sorted(w.found);
}

walker TopoWalker {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can hub_entry with PlanHub entry {
        print(["topo_hub", here.title]);
        seeds: list[object] = [];
        for ph in [here ->:HubLink:->][?:Phase] {
            seeds.append(ph);
        }
        for wi in [here ->:HubLink:->][?:WorkItem] {
            seeds.append(wi);
        }
        visit seeds;
    }

    can phase_entry with Phase entry {
        print(["topo_phase", here.num]);
        kids: list[WorkItem] = [];
        for wi in [here ->:InPhase:->][?:WorkItem] {
            kids.append(wi);
        }
        visit kids;
    }

    can item_entry with WorkItem entry {
        if here.wid in self.claimed {
            skip;
        }
        deps: list[WorkItem] = [];
        for dep in [here ->:DependsOn:->][?:WorkItem] {
            deps.append(dep);
        }
        if deps {
            visit :0: deps;
        }
        self.claimed[here.wid] = True;
        self.order.append(here.wid);
        print(["topo_item", here.wid]);
    }
}

def topo_ids(hub: PlanHub) -> list[str] {
    w = hub spawn TopoWalker(claimed={}, order=[]);
    return w.order;
}

test "reachable_from_wi7_includes_diamond_closure" {
    hub = build_plan();
    got = reachable_ids(hub, "WI-7");
    exp = sorted(["WI-7", "WI-8", "WI-9", "WI-10", "WI-11", "WI-13", "WI-14", "WI-15"]);
    assert got == exp;
}

test "diamond_revisit_no_duplicate_wi10" {
    hub = build_plan();
    w = hub spawn ReachWalker(start="WI-8", claimed={}, active=False, found=[]);
    got = sorted(w.found);
    exp = sorted(["WI-8", "WI-10", "WI-11", "WI-13", "WI-14", "WI-15"]);
    assert got == exp;
    assert len(got) == len(exp);
}

test "unknown_start_returns_empty" {
    hub = build_plan();
    got = reachable_ids(hub, "WI-404");
    assert got == [];
}

test "topo_respects_dependency_order" {
    hub = build_plan();
    got = topo_ids(hub);
    idx: dict[str, int] = {};
    i = 0;
    for wid in got {
        idx[wid] = i;
        i = i + 1;
    }
    assert idx["WI-3"] < idx["WI-7"];
    assert idx["WI-8"] < idx["WI-10"];
    assert idx["WI-9"] < idx["WI-10"];
    assert idx["WI-10"] < idx["WI-11"];
    assert idx["WI-13"] < idx["WI-14"];
}

test "open_items_sorted" {
    hub = build_plan();
    got = open_items(hub);
    assert got == ["WI-14", "WI-15"];
}

test "unknown_item_phase_is_none" {
    hub = build_plan();
    assert item_phase(hub, "WI-404") == None;
    assert item_phase(hub, "WI-14") == -1;
    assert item_phase(hub, "WI-3") == 0;
}
