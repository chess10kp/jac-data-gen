"""fastlane/fastlane#29496 — buffered IO sync inflates reachable build-phase cost."""

glob SYNC_PENALTY_MS = 12000;

node BuildPhase {
    has pid: str;
    has base_ms: int = 0;
}

edge PhaseDep {}

walker ReachPhaseWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with BuildPhase entry {
        if here.pid in self.claimed { skip; }
        self.claimed[here.pid] = True;
        self.order.append(here.pid);
        kids = _sorted_out(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_out(nd: BuildPhase) -> list[BuildPhase] {
    kids: list[BuildPhase] = [];
    for ch in [nd ->:PhaseDep:->][?:BuildPhase] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.pid); }
    names = sorted(names);
    ordered: list[BuildPhase] = [];
    for nm in names { for ch in kids { if ch.pid == nm { ordered.append(ch); } } }
    return ordered;
}

def _find_phase(pid: str, store: dict) -> BuildPhase | None {
    nmap = store["nodes"] as dict[str, BuildPhase];
    if pid in nmap { return nmap[pid]; }
    return None;
}

def _effective_ms(nd: BuildPhase, sync_io: bool) -> int {
    if sync_io and nd.pid == "launch_screen" { return nd.base_ms + SYNC_PENALTY_MS; }
    return nd.base_ms;
}

def fresh_build_store() -> dict { return {"phases": {}, "deps": {}, "rev": {}, "nodes": {}}; }

def register_phase(phase_id: str, base_ms: int, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_build_store(); }
    (s["phases"] as dict[str, int])[phase_id] = base_ms;
    deps = s["deps"] as dict[str, list[str]];
    if phase_id not in deps { deps[phase_id] = []; }
    rev = s["rev"] as dict[str, list[str]];
    if phase_id not in rev { rev[phase_id] = []; }
    nd = BuildPhase(pid=phase_id, base_ms=base_ms);
    root ++> nd;
    (s["nodes"] as dict[str, BuildPhase])[phase_id] = nd;
    return s;
}

def add_phase_dependency(source_id: str, target_id: str, store: dict) {
    pmap = store["phases"] as dict[str, int];
    if source_id not in pmap or target_id not in pmap { raise KeyError("unknown phase id"); }
    if source_id == target_id { return; }
    src_nd = _find_phase(source_id, store);
    tgt_nd = _find_phase(target_id, store);
    if src_nd is not None and tgt_nd is not None {
        seen = False;
        for ex in [src_nd ->:PhaseDep:->][?:BuildPhase] { if ex.pid == target_id { seen = True; } }
        if not seen { src_nd +>:PhaseDep:+> tgt_nd; }
    }
    outs = store["deps"] as dict[str, list[str]];
    if source_id not in outs { outs[source_id] = []; }
    if target_id not in outs[source_id] { outs[source_id].append(target_id); outs[source_id] = sorted(outs[source_id]); }
    revs = store["rev"] as dict[str, list[str]];
    if target_id not in revs { revs[target_id] = []; }
    if source_id not in revs[target_id] { revs[target_id].append(source_id); revs[target_id] = sorted(revs[target_id]); }
}

def reachable_phases(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["phases"] as dict) { raise KeyError(start_id); }
    start_nd = _find_phase(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn ReachPhaseWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for pid in w.order { if pid != start_id { reach.append(pid); } }
    return reach;
}

def build_duration_ms(start_id: str, store: dict, sync_io: bool = False) -> int {
    if start_id not in (store["phases"] as dict) { raise KeyError(start_id); }
    start_nd = _find_phase(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn ReachPhaseWalk(claimed={}, order=[]);
    total = 0;
    for pid in w.order {
        nd = _find_phase(pid, store);
        if nd is not None { total += _effective_ms(nd, sync_io); }
    }
    return total;
}

def build_report(start_id: str, store: dict, sync_io: bool = False) -> dict {
    reach = reachable_phases(start_id, store);
    direct = list((store["deps"] as dict[str, list[str]]).get(start_id, []));
    return {"direct": direct, "reach": reach, "reach_count": len(reach), "duration_ms": build_duration_ms(start_id, store, sync_io), "sync_io": sync_io};
}
