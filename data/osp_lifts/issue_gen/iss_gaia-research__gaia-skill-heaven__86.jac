"""gaia-research/gaia-skill-heaven#86 — Termux I/O penalty on boot-step reach cost."""

glob TERMUX_IO_PENALTY_MS = 8000;

node BootStep {
    has sid: str;
    has base_ms: int = 0;
}

edge BootDep {}

walker ReachBootWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with BootStep entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        self.order.append(here.sid);
        kids = _sorted_out(here);
        i = len(kids) - 1;
        while i >= 0 { visit :0: [kids[i]]; i -= 1; }
    }
}

def _sorted_out(nd: BootStep) -> list[BootStep] {
    kids: list[BootStep] = [];
    for ch in [nd ->:BootDep:->][?:BootStep] { kids.append(ch); }
    names: list[str] = [];
    for ch in kids { names.append(ch.sid); }
    names = sorted(names);
    ordered: list[BootStep] = [];
    for nm in names { for ch in kids { if ch.sid == nm { ordered.append(ch); } } }
    return ordered;
}

def _find_step(sid: str, store: dict) -> BootStep | None {
    nmap = store["nodes"] as dict[str, BootStep];
    if sid in nmap { return nmap[sid]; }
    return None;
}

def _effective_ms(nd: BootStep, termux_io: bool) -> int {
    if termux_io and (nd.sid == "npm_unpack" or nd.sid == "copy_skills") {
        return nd.base_ms + TERMUX_IO_PENALTY_MS;
    }
    return nd.base_ms;
}

def fresh_boot_store() -> dict { return {"steps": {}, "deps": {}, "rev": {}, "nodes": {}}; }

def register_boot_step(step_id: str, base_ms: int, store: dict | None = None) -> dict {
    s = store;
    if s is None { s = fresh_boot_store(); }
    (s["steps"] as dict[str, int])[step_id] = base_ms;
    deps = s["deps"] as dict[str, list[str]];
    if step_id not in deps { deps[step_id] = []; }
    rev = s["rev"] as dict[str, list[str]];
    if step_id not in rev { rev[step_id] = []; }
    nd = BootStep(sid=step_id, base_ms=base_ms);
    root ++> nd;
    (s["nodes"] as dict[str, BootStep])[step_id] = nd;
    return s;
}

def add_boot_dependency(source_id: str, target_id: str, store: dict) {
    smap = store["steps"] as dict[str, int];
    if source_id not in smap or target_id not in smap { raise KeyError("unknown boot step id"); }
    if source_id == target_id { return; }
    src_nd = _find_step(source_id, store);
    tgt_nd = _find_step(target_id, store);
    if src_nd is not None and tgt_nd is not None {
        seen = False;
        for ex in [src_nd ->:BootDep:->][?:BootStep] { if ex.sid == target_id { seen = True; } }
        if not seen { src_nd +>:BootDep:+> tgt_nd; }
    }
    outs = store["deps"] as dict[str, list[str]];
    if source_id not in outs { outs[source_id] = []; }
    if target_id not in outs[source_id] { outs[source_id].append(target_id); outs[source_id] = sorted(outs[source_id]); }
    revs = store["rev"] as dict[str, list[str]];
    if target_id not in revs { revs[target_id] = []; }
    if source_id not in revs[target_id] { revs[target_id].append(source_id); revs[target_id] = sorted(revs[target_id]); }
}

def direct_downstream(step_id: str, store: dict) -> list[str] {
    if step_id not in (store["steps"] as dict) { raise KeyError(step_id); }
    return list((store["deps"] as dict[str, list[str]]).get(step_id, []));
}

def reachable_steps(start_id: str, store: dict) -> list[str] {
    if start_id not in (store["steps"] as dict) { raise KeyError(start_id); }
    start_nd = _find_step(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn ReachBootWalk(claimed={}, order=[]);
    reach: list[str] = [];
    for sid in w.order { if sid != start_id { reach.append(sid); } }
    return reach;
}

def boot_duration_ms(start_id: str, store: dict, termux_io: bool = False) -> int {
    if start_id not in (store["steps"] as dict) { raise KeyError(start_id); }
    start_nd = _find_step(start_id, store);
    if start_nd is None { raise KeyError(start_id); }
    w = start_nd spawn ReachBootWalk(claimed={}, order=[]);
    total = 0;
    for sid in w.order {
        nd = _find_step(sid, store);
        if nd is not None { total += _effective_ms(nd, termux_io); }
    }
    return total;
}

def boot_report(start_id: str, store: dict, termux_io: bool = False) -> dict {
    reach = reachable_steps(start_id, store);
    direct = direct_downstream(start_id, store);
    return {"direct": direct, "reach": reach, "reach_count": len(reach), "duration_ms": boot_duration_ms(start_id, store, termux_io), "termux_io": termux_io};
}
