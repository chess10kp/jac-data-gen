"""RicoSuter/Namotion.Interceptor#410 — stranded fallback edges on partial detach."""

class DelegationCycleError(Exception) {}

node Subject {
    has sid: str;
    has parent_id: str = "";
    has ref_count: int = 1;
    has prop_removed: bool = False;
}

edge FallbackTo: Subject --> Subject {
    has prop_name: str = "";
}

walker FallbackReachWalk {
    has claimed: dict[str, bool] = {};
    has hits: list[str] = [];
    has origin: str = "";

    can step with Subject entry {
        if here.sid in self.claimed { skip; }
        self.claimed[here.sid] = True;
        if here.sid != self.origin { self.hits.append(here.sid); }
        nbrs = [here ->:FallbackTo:->][?:Subject];
        nms: list[str] = [];
        for n in nbrs { nms.append(n.sid); }
        for nm in sorted(nms) {
            for n in nbrs {
                if n.sid == nm and n.sid not in self.claimed { visit [n]; }
            }
        }
    }
}

walker ResolveServiceWalk {
    has service_name: str = "";
    has claimed: dict[str, bool] = {};
    has reg_services: dict[str, list[str]] = {};
    has resolved: str = "";
    has cycle: bool = False;
    has cycle_node: str = "";

    can step with Subject entry {
        if here.sid in self.claimed {
            svcs = self.reg_services.get(here.sid, []) as list[str];
            if svcs is None or len(svcs) == 0 {
                self.cycle = True;
                self.cycle_node = here.sid;
            }
            skip;
        }
        self.claimed[here.sid] = True;
        svcs = self.reg_services.get(here.sid, []) as list[str];
        if svcs is not None {
            for s in svcs {
                if s == self.service_name {
                    self.resolved = here.sid;
                    disengage;
                }
            }
        }
        nbrs = [here ->:FallbackTo:->][?:Subject];
        nms: list[str] = [];
        for n in nbrs { nms.append(n.sid); }
        nms.sort();
        nms.reverse();
        for nm in nms {
            for n in nbrs {
                if n.sid == nm { visit :0: [n]; }
            }
        }
    }
}

walker PureDelegatorCycleWalk {
    has path: list[str] = [];
    has on_path: dict[str, bool] = {};
    has cyclic: dict[str, bool] = {};
    has reg_services: dict[str, list[str]] = {};
    has origin: str = "";

    can step with Subject entry {
        if here.sid in self.on_path { skip; }
        nt: list[str] = [];
        for x in self.path { nt.append(x); }
        nt.append(here.sid);
        nop: dict[str, bool] = {**self.on_path, here.sid: True};
        nbrs = [here ->:FallbackTo:->][?:Subject];
        nms: list[str] = [];
        for n in nbrs { nms.append(n.sid); }
        for nm in sorted(nms) {
            for n in nbrs {
                if n.sid == nm {
                    if n.sid in nop {
                        idx = -1;
                        for i in range(len(nt)) {
                            if nt[i] == n.sid { idx = i; }
                        }
                        if idx >= 0 {
                            pure = True;
                            for j in range(idx, len(nt)) {
                                sid = nt[j];
                                svcs = self.reg_services.get(sid, []);
                                if svcs is not None and len(svcs) > 0 { pure = False; }
                            }
                            if pure {
                                for j in range(idx, len(nt)) {
                                    self.cyclic[nt[j]] = True;
                                }
                            }
                        }
                    } else {
                        n spawn PureDelegatorCycleWalk(
                            path=nt,
                            on_path=nop,
                            cyclic=self.cyclic,
                            reg_services=self.reg_services,
                            origin=self.origin,
                        );
                    }
                }
            }
        }
    }
}

def _find_subject(reg: dict, sid: str) -> Subject | None {
    for nd in [root -->][?:Subject] {
        if nd.sid == sid { return nd; }
    }
    return None;
}

def create_registry() -> dict {
    return {
        "subjects": {},
        "fallbacks": {},
        "services": {},
        "props": {},
    };
}

def add_subject(reg: dict, subject_id: str, parent_id: str | None = None) {
    par = "";
    if parent_id is not None { par = parent_id; }
    reg["subjects"][subject_id] = {
        "parent": parent_id,
        "ref_count": 1,
        "prop_removed": False,
    };
    if subject_id not in reg["fallbacks"] { reg["fallbacks"][subject_id] = []; }
    if subject_id not in reg["services"] { reg["services"][subject_id] = []; }
    nd = Subject(sid=subject_id, parent_id=par, ref_count=1, prop_removed=False);
    root ++> nd;
}

def bind_property(reg: dict, owner_id: str, prop_name: str, target_id: str) {
    reg["props"][(owner_id, prop_name)] = target_id;
    adj = reg["fallbacks"].get(owner_id, []) as list[str];
    if adj is None { adj = []; reg["fallbacks"][owner_id] = adj; }
    seen = False;
    for t in adj { if t == target_id { seen = True; } }
    if not seen { adj.append(target_id); }
    owner = _find_subject(reg, owner_id);
    tgt = _find_subject(reg, target_id);
    if owner is not None and tgt is not None {
        dup = False;
        for ex in [owner ->:FallbackTo:->][?:Subject] {
            if ex.sid == target_id { dup = True; }
        }
        if not dup { owner +>:FallbackTo(prop_name=prop_name):+> tgt; }
    }
}

def register_service(reg: dict, subject_id: str, service_name: str) {
    svc = reg["services"].get(subject_id, []) as list[str];
    if svc is None { svc = []; reg["services"][subject_id] = svc; }
    found = False;
    for s in svc { if s == service_name { found = True; } }
    if not found { svc.append(service_name); }
}

def _remove_inherited_fallbacks(reg: dict, subject_id: str) {
    drop: dict[str, bool] = {};
    props = reg["props"];
    pk: list = [];
    for k in props.keys() { pk.append(k); }
    for key in pk {
        owner = key[0];
        if owner == subject_id { drop[props[key]] = True; }
    }
    owner_nd = _find_subject(reg, subject_id);
    if owner_nd is not None {
        for tgt_id in drop.keys() {
            tgt_nd = _find_subject(reg, tgt_id);
            if tgt_nd is not None { owner_nd del ->:FallbackTo:-> tgt_nd; }
        }
    }
    old = reg["fallbacks"].get(subject_id, []) as list[str];
    kept: list[str] = [];
    if old is not None {
        for t in old {
            if not (t in drop) { kept.append(t); }
        }
    }
    reg["fallbacks"][subject_id] = kept;
}

def detach_subject(reg: dict, subject_id: str, property_removed: bool) {
    sub = reg["subjects"][subject_id];
    sub["ref_count"] = 0;
    if property_removed { sub["prop_removed"] = True; }
    nd = _find_subject(reg, subject_id);
    if nd is not None {
        nd.ref_count = 0;
        if property_removed { nd.prop_removed = True; }
    }
    if sub["ref_count"] == 0 and sub["prop_removed"] {
        _remove_inherited_fallbacks(reg, subject_id);
    }
}

def list_fallback_edges(reg: dict) -> list[tuple[str, str]] {
    out: list[tuple[str, str]] = [];
    srcs: list[str] = [];
    fb = reg["fallbacks"] as dict[str, list[str]];
    for k in fb { srcs.append(k); }
    srcs.sort();
    for src in srcs {
        tgts: list[str] = [];
        raw = fb.get(src, []) as list[str];
        if raw is not None {
            for t in raw { tgts.append(t); }
        }
        tgts.sort();
        for tgt in tgts { out.append((src, tgt)); }
    }
    return out;
}

def resolve_service(reg: dict, subject_id: str, service_name: str) -> str | None {
    nd = _find_subject(reg, subject_id);
    if nd is None { return None; }
    w = nd spawn ResolveServiceWalk(
        service_name=service_name,
        claimed={},
        reg_services=reg["services"],
        resolved="",
        cycle=False,
        cycle_node="",
    );
    if w.cycle { raise DelegationCycleError(w.cycle_node); }
    if w.resolved == "" { return None; }
    return w.resolved;
}

def delegation_cycle_nodes(reg: dict) -> list[str] {
    cyclic: dict[str, bool] = {};
    starts: list[str] = [];
    subj = reg["subjects"] as dict[str, dict];
    for k in subj { starts.append(k); }
    starts.sort();
    for start in starts {
        svcs = (reg["services"] as dict[str, list[str]]).get(start, []) as list[str];
        if svcs is not None and len(svcs) > 0 { continue; }
        nd = _find_subject(reg, start);
        if nd is None { continue; }
        nd spawn PureDelegatorCycleWalk(
            path=[],
            on_path={},
            cyclic=cyclic,
            reg_services=reg["services"],
            origin=start,
        );
    }
    out: list[str] = [];
    for k in cyclic.keys() { out.append(k); }
    return sorted(out);
}

def reachable_via_fallback(reg: dict, subject_id: str) -> list[str] {
    nd = _find_subject(reg, subject_id);
    if nd is None { return []; }
    w = nd spawn FallbackReachWalk(claimed={}, hits=[], origin=subject_id);
    return sorted(w.hits);
}
