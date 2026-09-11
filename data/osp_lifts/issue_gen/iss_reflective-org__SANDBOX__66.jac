"""reflective-org/SANDBOX#66 — dependency DAG engine (OSP lift)."""

obj DeriveStore {
    has derived_from: dict[str, list[str]] = {};
    has modes: dict[str, str] = {};
    has values: dict[str, object] = {};
}

node Field { has fid: str; }
edge Depends {}

walker DownstreamWalk {
    has claimed: dict[str, bool] = {};
    has reached: list[str] = [];
    has origin: str = "";

    can step with Field entry {
        if here.fid in self.claimed { skip; }
        self.claimed[here.fid] = True;
        if here.fid != self.origin { self.reached.append(here.fid); }
        visit [->:Depends:->] else { disengage; };
    }
}

walker CycleProbe {
    has on_stack: dict[str, bool] = {};
    has has_cycle: bool = False;

    can step with Field entry {
        if self.has_cycle { skip; }
        if here.fid in self.on_stack { self.has_cycle = True; skip; }
        self.on_stack[here.fid] = True;
        visit [->:Depends:->] else { disengage; };
    }

    can unwind with Field exit { self.on_stack[here.fid] = False; }
}

def _find(fid: str) -> Field | None {
    for n in [-->][?:Field] { if n.fid == fid { return n; } }
    return None;
}

def load_registry(
    derived_from: dict[str, list[str]],
    modes: dict[str, str],
    values: dict[str, object],
) -> DeriveStore {
    mp: dict[str, Field] = {};
    for fid in derived_from {
        if fid not in mp { fresh = Field(fid=fid); root ++> fresh; mp[fid] = fresh; }
        for dep in derived_from[fid] {
            if dep not in mp { fresh = Field(fid=dep); root ++> fresh; mp[dep] = fresh; }
        }
    }
    for fid in derived_from {
        src = mp.get(fid, None);
        if src is None { continue; }
        for dep in derived_from[fid] {
            tgt = mp.get(dep, None);
            if tgt is not None { src +>:Depends():+> tgt; }
        }
    }
    return DeriveStore(derived_from=derived_from, modes=modes, values=dict(values));
}

def detect_cycle(g: DeriveStore) -> bool {
    w = root spawn CycleProbe(on_stack={}, has_cycle=False);
    return w.has_cycle;
}

def downstream_closure(g: DeriveStore, field_id: str) -> list[str] {
    if field_id not in g.derived_from { return []; }
    anchor = _find(field_id);
    if anchor is None { return []; }
    w = anchor spawn DownstreamWalk(claimed={}, reached=[], origin=field_id);
    return sorted(w.reached);
}

def resolve_change(g: DeriveStore, field_id: str, new_value: object) -> tuple[dict[str, object], list[str]] {
    out = dict(g.values);
    stale: list[str] = [];
    out[field_id] = new_value;
    for fid in downstream_closure(g, field_id) {
        if g.modes.get(fid, "auto") == "auto" { out[fid] = "derived(" + field_id + ")"; }
        else { stale.append(fid); }
    }
    return (out, sorted(stale));
}
