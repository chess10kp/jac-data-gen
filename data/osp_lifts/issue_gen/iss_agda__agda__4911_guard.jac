"""agda/agda#4911 — mutual Cx/Hyp scope vs separate modules."""

node Cx {
    has cid: str;
    has layout: str = "works";
}

node Hyp {
    has hid: str;
    has owner_cid: str;
}

edge Owns {}
edge Extends {}

obj MutualScope {
    has graph_root: Cx;
    has layout: str;
    has hyp_map: dict[str, str];
    has cx_seq: int = 1;
    has hyp_seq: int = 1;

    def empty(self) -> str {
        return self.graph_root.cid;
    }

    def bind_hyp(self, gamma: str) -> str {
        g = self._find_cx(gamma);
        if g is None { return ""; }
        hid = "h" + str(self.hyp_seq);
        self.hyp_seq += 1;
        h = Hyp(hid=hid, owner_cid=gamma);
        root ++> h;
        g +>:Owns:+> h;
        self.hyp_map[hid] = gamma;
        return hid;
    }

    def extend(self, gamma: str, hyp: str) -> str {
        if gamma == "" or hyp == "" { return ""; }
        g = self._find_cx(gamma);
        if g is None { return ""; }
        hp = self._find_hyp(hyp);
        if hp is None { return ""; }
        if hyp not in self.hyp_map { return ""; }
        if self.hyp_map[hyp] != gamma { return ""; }
        cid = "cx" + str(self.cx_seq);
        self.cx_seq += 1;
        ext = Cx(cid=cid, layout=self.layout);
        root ++> ext;
        g +>:Extends:+> ext;
        ext +>:Owns:+> hp;
        return cid;
    }

    def constructors(self) -> list[str] {
        w = self.graph_root spawn ScopeCollect(layout=self.layout);
        out: list[str] = [];
        for nm in sorted(w.names) {
            out.append(nm);
        }
        return out;
    }

    def in_scope(self, name: str) -> bool {
        names: list[str] = self.constructors();
        for nm in names {
            if nm == name { return True; }
        }
        return False;
    }

    def weaken(self, hyp: str, src_gamma: str) -> str | None {
        if not self.in_scope(",") { return None; }
        ext_cid = self.extend(src_gamma, hyp);
        if ext_cid == "" { return None; }
        new_h = self.bind_hyp(ext_cid);
        if new_h == "" { return None; }
        return new_h;
    }

    def _find_cx(self, cid: str) -> Cx | None {
        w = self.graph_root spawn FindCx(target=cid);
        return w.found;
    }

    def _find_hyp(self, hid: str) -> Hyp | None {
        w = self.graph_root spawn FindHyp(target=hid);
        return w.found;
    }
}

walker ScopeCollect {
    has layout: str;
    has names: list[str] = [];
    can collect with Cx entry {
        scope_out: list[str] = [];
        scope_out.append("scope");
        scope_out.append(self.layout);
        print scope_out;
        if self.layout == "works" {
            if "," not in self.names { self.names.append(","); }
            if "." not in self.names { self.names.append("."); }
            if "Hyp" not in self.names { self.names.append("Hyp"); }
        } else {
            if "." not in self.names { self.names.append("."); }
            if "Hyp" not in self.names { self.names.append("Hyp"); }
        }
        disengage;
    }
}

walker FindCx {
    has target: str;
    has found: Cx | None = None;
    has claimed: dict[str, bool] = {};
    can step with Cx entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        find_out: list[str] = [];
        find_out.append("find_cx");
        find_out.append(here.cid);
        print find_out;
        if here.cid == self.target {
            self.found = here;
            disengage;
        }
        raw: list[Cx] = [here ->:Extends:->][?:Cx];
        kids: list[Cx] = [];
        for ch in raw { kids.append(ch); }
        for ch in kids { visit :0: [ch]; }
    }
}

walker FindHyp {
    has target: str;
    has found: Hyp | None = None;
    has claimed_cx: dict[str, bool] = {};
    has claimed_hyp: dict[str, bool] = {};
    can scan_cx with Cx entry {
        if here.cid in self.claimed_cx { skip; }
        self.claimed_cx[here.cid] = True;
        scan_cx_out: list[str] = [];
        scan_cx_out.append("scan_cx");
        scan_cx_out.append(here.cid);
        print scan_cx_out;
        hyps: list[Hyp] = [here ->:Owns:->][?:Hyp];
        for h in hyps { visit :0: [h]; }
        raw: list[Cx] = [here ->:Extends:->][?:Cx];
        kids: list[Cx] = [];
        for ch in raw { kids.append(ch); }
        for ch in kids { visit :0: [ch]; }
    }
    can scan_hyp with Hyp entry {
        if here.hid in self.claimed_hyp { skip; }
        self.claimed_hyp[here.hid] = True;
        cur: Hyp = here;
        scan_hyp_out: list[str] = [];
        scan_hyp_out.append("scan_hyp");
        scan_hyp_out.append(cur.hid);
        print scan_hyp_out;
        if cur.hid == self.target {
            self.found = cur;
            disengage;
        }
    }
}

walker CountCx {
    has claimed: dict[str, bool] = {};
    has count: int = 0;
    can step with Cx entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.count += 1;
        count_out: list[str] = [];
        count_out.append("count");
        count_out.append(here.cid);
        count_out.append(str(self.count));
        print count_out;
        raw: list[Cx] = [here ->:Extends:->][?:Cx];
        kids: list[Cx] = [];
        for ch in raw { kids.append(ch); }
        for ch in kids { visit :0: [ch]; }
    }
}

def create_scope(layout: str) -> MutualScope {
    graph_root = Cx(cid="cx0", layout=layout);
    root ++> graph_root;
    hyp_map: dict[str, str] = {};
    ms = MutualScope(
        graph_root=graph_root,
        layout=layout,
        hyp_map=hyp_map,
        cx_seq=1,
        hyp_seq=1
    );
    return ms;
}

test "works_layout_constructors" {
    ms = create_scope("works");
    assert ms.empty() == "cx0";
    c: list[str] = ms.constructors();
    assert c == [",", ".", "Hyp"];
}

test "broken_layout_constructors" {
    ms = create_scope("broken");
    c: list[str] = ms.constructors();
    assert c == [".", "Hyp"];
}

test "bind_and_extend" {
    ms = create_scope("works");
    h = ms.bind_hyp("cx0");
    assert h == "h1";
    ext = ms.extend("cx0", h);
    assert ext == "cx1";
    assert ms.in_scope(",") == True;
    assert ms.in_scope("nope") == False;
}

test "weaken_works" {
    ms = create_scope("works");
    h = ms.bind_hyp("cx0");
    wh = ms.weaken(h, "cx0");
    assert wh == "h2";
}

test "weaken_no_comma" {
    ms = create_scope("broken");
    h = ms.bind_hyp("cx0");
    wh = ms.weaken(h, "cx0");
    assert wh is None;
}

test "extend_invalid" {
    ms = create_scope("works");
    assert ms.extend("", "h1") == "";
    assert ms.extend("cx0", "") == "";
    assert ms.extend("missing", "h1") == "";
}
