# iss_agda__agda__4911.jac — agda/agda#4911 mutual vs separate Cx/Hyp scope
"""Lift: manual declaration cascade + recursive scope walk for mutual blocks."""

node Registry {
    has rid: str;
    has mode: str = "separate";
    has cx_done: bool = False;
    has hyp_done: bool = False;
    has comma_live: bool = False;
    has visible: dict[str, list[str]] = {};
    has wk_ok: dict[str, bool] = {};
}

node Cx {
    has cid: str;
    has kind: str = "dot";
}

node Hyp {
    has hid: str;
    has ctx_cid: str;
}

edge InReg {}
edge Binds {}
edge Parent {}

walker Cascade {
    has claimed: dict[str, bool] = {};
    has reg: Registry;

    can sweep_cx with Cx entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        syms: list[str] = self.reg.visible[here.cid] if here.cid in self.reg.visible else [];
        if here.kind == "dot" {
            syms.append("dot");
        } else {
            syms.append("comma");
        }
        self.reg.visible[here.cid] = syms;
        print("cascade cx ", here.cid);
        kids: list[Cx] = [];
        for ch in [here ->:Parent:->][?:Cx] {
            kids.append(ch);
        }
        if kids { visit :0: kids; } else { disengage; }
    }

    can sweep_hyp with Hyp entry {
        if here.hid in self.claimed { skip; }
        self.claimed[here.hid] = True;
        ok: bool = self.reg.comma_live;
        self.reg.wk_ok[here.hid] = ok;
        print("cascade hyp ", here.hid, " comma=", ok);
        disengage;
    }
}

walker ScopeProbe {
    has claimed: dict[str, bool] = {};
    has target: str = "";
    has hit: bool = False;

    can walk_cx with Cx entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid == self.target {
            self.hit = True;
            print("scope hit ", here.cid);
            disengage;
        }
        kids: list[Cx] = [];
        for ch in [here ->:Parent:->][?:Cx] {
            kids.append(ch);
        }
        if kids { visit :0: kids; } else { disengage; }
    }
}

def make_engine(mode: str) -> str {
    rid: str = "eng_" + mode;
    reg = Registry(rid=rid, mode=mode);
    root ++> reg;
    return rid;
}

def _reg(eid: str) -> Registry {
    for r in [root ->:InReg:->][?:Registry] {
        if r.rid == eid { return r; }
    }
    for r in [root ->:InReg:->][?:Registry] {
        if r.rid == eid { return r; }
    }
    raise Exception("unknown engine");
}

def cx_dot(engine: str, cid: str) {
    reg = _reg(engine);
    nd = Cx(cid=cid, kind="dot");
    reg +>:InReg:+> nd;
}

def cx_comma(engine: str, cid: str, parent: str, hyp: str) {
    reg = _reg(engine);
    nd = Cx(cid=cid, kind="comma");
    reg +>:InReg:+> nd;
    for p in [reg ->:InReg:->][?:Cx] {
        if p.cid == parent { p +>:Parent:+> nd; }
    }
    for h in [reg ->:InReg:->][?:Hyp] {
        if h.hid == hyp { h +>:Binds:+> nd; }
    }
}

def hyp_decl(engine: str, hid: str, ctx_cid: str) {
    reg = _reg(engine);
    h = Hyp(hid=hid, ctx_cid=ctx_cid);
    reg +>:InReg:+> h;
    for c in [reg ->:InReg:->][?:Cx] {
        if c.cid == ctx_cid { h +>:Binds:+> c; }
    }
}

def finalize_decls(engine: str) {
    reg = _reg(engine);
    if reg.mode == "separate" {
        reg.comma_live = True;
        reg.cx_done = True;
        reg.hyp_done = True;
    } else {
        reg.cx_done = True;
        reg.hyp_done = True;
        reg.comma_live = False;
    }
    w = reg spawn Cascade(claimed={}, reg=reg);
    print("finalize ", reg.rid, " mode=", reg.mode);
}

def visible(engine: str, ctx_cid: str) -> list[str] {
    reg = _reg(engine);
    if ctx_cid in reg.visible {
        return sorted(reg.visible[ctx_cid]);
    }
    return [];
}

def wk_hyp_scope_ok(engine: str, hyp: str) -> bool {
    reg = _reg(engine);
    if hyp in reg.wk_ok {
        return reg.wk_ok[hyp];
    }
    return False;
}

def decl_order(mode: str) -> list[str] {
    if mode == "separate" {
        return ["Cx", "Hyp", "wk_hyp"];
    }
    if mode == "mutual" {
        return ["Cx", "Hyp", "wk_hyp"];
    }
    return [];
}

def ctx_reachable(engine: str, ctx_cid: str) -> bool {
    reg = _reg(engine);
    for c in [reg ->:InReg:->][?:Cx] {
        if c.cid == "G0" {
            w = c spawn ScopeProbe(claimed={}, target=ctx_cid, hit=False);
            return w.hit;
        }
    }
    return False;
}
