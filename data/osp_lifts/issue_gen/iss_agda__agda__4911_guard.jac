"""Mutual Cx/Hyp scope lift — agda/agda#4911."""

node Ctx {
    has cid: str;
}

node Hyp {
    has cid: str;
    has atom: str;
}

edge Parent {}
edge HasHyp {}
edge Param {}

walker FindNode {
    has target: str;
    has claimed: dict[str, bool] = {};
    has ctx_hit: Ctx | None = None;
    has hyp_hit: Hyp | None = None;

    can scan_ctx with Ctx entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print("find", here.cid);
        if here.cid == self.target {
            self.ctx_hit = here;
            disengage;
        }
        has_edge: bool = False;
        for ch in [here ->:Parent:->][?:Ctx] {
            has_edge = True;
            visit :0: [ch];
        }
        for h in [here ->:HasHyp:->][?:Hyp] {
            has_edge = True;
            visit :0: [h];
        }
        if not has_edge {
            disengage;
        }
    }

    can scan_hyp with Hyp entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        print("find", here.cid);
        if here.cid == self.target {
            self.hyp_hit = here;
            disengage;
        }
        has_edge: bool = False;
        for g in [here ->:Param:->][?:Ctx] {
            has_edge = True;
            visit :0: [g];
        }
        if not has_edge {
            disengage;
        }
    }
}

walker ClosureWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];

    can walk_ctx with Ctx entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print("closure", here.cid);
        has_edge: bool = False;
        for ch in [here ->:Parent:->][?:Ctx] {
            has_edge = True;
            visit :0: [ch];
        }
        for h in [here ->:HasHyp:->][?:Hyp] {
            has_edge = True;
            visit :0: [h];
        }
        if not has_edge {
            disengage;
        }
    }

    can walk_hyp with Hyp entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print("closure", here.cid);
        has_edge: bool = False;
        for g in [here ->:Param:->][?:Ctx] {
            has_edge = True;
            visit :0: [g];
        }
        if not has_edge {
            disengage;
        }
    }
}

def find_ctx(cid: str) -> Ctx | None {
    w = root spawn FindNode(target=cid, claimed={});
    return w.ctx_hit;
}

def find_hyp(cid: str) -> Hyp | None {
    w = root spawn FindNode(target=cid, claimed={});
    return w.hyp_hit;
}

def empty_context -> str {
    g = Ctx(cid="Cx·");
    root ++> g;
    return g.cid;
}

def make_hypothesis(gamma_id: str, atom: str) -> str | None {
    gamma = find_ctx(gamma_id);
    if gamma is None {
        return None;
    }
    hid = "Hyp:" + atom + "@" + gamma_id;
    h = Hyp(cid=hid, atom=atom);
    root ++> h;
    h +>:Param:+> gamma;
    return h.cid;
}

def extend_context(gamma_id: str, hyp_id: str) -> str | None {
    gamma = find_ctx(gamma_id);
    hyp = find_hyp(hyp_id);
    if gamma is None or hyp is None {
        return None;
    }
    param_ok: bool = False;
    for g in [hyp ->:Param:->][?:Ctx] {
        if g.cid == gamma_id {
            param_ok = True;
        }
    }
    if not param_ok {
        return None;
    }
    nid = "Cx:" + gamma_id + "," + hyp_id;
    ext = Ctx(cid=nid);
    root ++> ext;
    ext +>:Parent:+> gamma;
    ext +>:HasHyp:+> hyp;
    return ext.cid;
}

def postulate_in_scope(gamma_id: str, hyp_id: str) -> bool {
    gamma = find_ctx(gamma_id);
    hyp = find_hyp(hyp_id);
    if gamma is None or hyp is None {
        return False;
    }
    for g in [hyp ->:Param:->][?:Ctx] {
        if g.cid == gamma_id {
            return True;
        }
    }
    return False;
}

def weaken_hypothesis(hyp_id: str, gamma_id: str, atom: str) -> str | None {
    if not postulate_in_scope(gamma_id, hyp_id) {
        return None;
    }
    ext_id = extend_context(gamma_id, hyp_id);
    if ext_id is None {
        return None;
    }
    ext = find_ctx(ext_id);
    if ext is None {
        return None;
    }
    wkid = "Hyp:wk:" + hyp_id + ":" + atom;
    wk = Hyp(cid=wkid, atom=atom);
    root ++> wk;
    wk +>:Param:+> ext;
    ext +>:HasHyp:+> wk;
    return wkid;
}

def mutual_closure(start_id: str) -> list[str] {
    anchor_ctx = find_ctx(start_id);
    anchor_hyp = find_hyp(start_id);
    if anchor_ctx is not None {
        w = anchor_ctx spawn ClosureWalker(claimed={});
    } else if anchor_hyp is not None {
        w = anchor_hyp spawn ClosureWalker(claimed={});
    } else {
        return [];
    }
    out: list[str] = [];
    for cid in sorted(w.found) {
        out.append(cid);
    }
    return out;
}

test "empty_context_root" {
    assert empty_context() == "Cx·";
}

test "make_and_extend_context" {
    gid = empty_context();
    hid = make_hypothesis(gid, "P");
    assert hid == "Hyp:P@Cx·";
    eid = extend_context(gid, hid);
    assert eid == "Cx:Cx·,Hyp:P@Cx·";
}

test "postulate_in_scope" {
    gid = empty_context();
    hid = make_hypothesis(gid, "P");
    assert postulate_in_scope(gid, hid) == True;
    assert postulate_in_scope(gid, "missing") == False;
}

test "weaken_hypothesis" {
    gid = empty_context();
    hid = make_hypothesis(gid, "P");
    wkid = weaken_hypothesis(hid, gid, "Q");
    assert wkid == "Hyp:wk:" + hid + ":Q";
}

test "mutual_closure_from_context" {
    gid = empty_context();
    assert mutual_closure(gid) == [gid];
}

test "mutual_closure_from_extended" {
    gid = empty_context();
    hid = make_hypothesis(gid, "P");
    eid = extend_context(gid, hid);
    got = mutual_closure(eid);
    want: list[str] = [];
    for cid in sorted([eid, gid, hid]) {
        want.append(cid);
    }
    assert got == want;
}
