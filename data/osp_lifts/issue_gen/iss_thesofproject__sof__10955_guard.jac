node Codec {
    has cid: str;
    has kind: str;
    has active: bool = False;
}

edge ResumeDep {}

walker ReachCollect {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can collect with Codec entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here.cid);
        print(here.cid);
        kids: list[Codec] = [here ->:ResumeDep:->][?:Codec];
        for kid in kids {
            visit [kid];
        }
    }
}

walker ResumeOrder {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    can order_step with Codec entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.order.append(here.cid);
        print(here.cid);
        kids: list[Codec] = [here ->:ResumeDep:->][?:Codec];
        for kid in kids {
            visit :0: [kid];
        }
    }
}

walker WedgeScan {
    has claimed: dict[str, bool] = {};
    has has_hdmi: bool = False;
    has has_active_analog: bool = False;
    can scan with Codec entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.cid);
        if here.kind == "hdmi" {
            self.has_hdmi = True;
        }
        if here.kind == "analog" and here.active {
            self.has_active_analog = True;
        }
        kids: list[Codec] = [here ->:ResumeDep:->][?:Codec];
        for kid in kids {
            visit [kid];
        }
    }
}

def make_codec(cid: str, kind: str, active: bool) -> Codec {
    nd: Codec = Codec(cid=cid, kind=kind, active=active);
    return nd;
}

def link_codecs(src: Codec, dst: Codec) -> None {
    src +>:ResumeDep:+> dst;
}

def get_reachable(start_codec: Codec) -> list[str] {
    w = start_codec spawn ReachCollect(claimed={}, found=[]);
    return w.found;
}

def get_resume_order(start_codec: Codec) -> list[str] {
    w = start_codec spawn ResumeOrder(claimed={}, order=[]);
    return w.order;
}

def will_wedge_on_resume(start_codec: Codec) -> bool {
    w = start_codec spawn WedgeScan(claimed={}, has_hdmi=False, has_active_analog=False);
    return w.has_hdmi and w.has_active_analog;
}

def is_reachable(start_codec: Codec, target: str) -> bool {
    reachable: list[str] = get_reachable(start_codec);
    for cid in reachable {
        if cid == target {
            return True;
        }
    }
    return False;
}

with entry {
    d: Codec = Codec(cid="dsp", kind="dsp", active=False);
    a: Codec = Codec(cid="analog", kind="analog", active=True);
    h: Codec = Codec(cid="hdmi", kind="hdmi", active=False);
    root ++> d;
    d +>:ResumeDep:+> a;
    d +>:ResumeDep:+> h;
    w = d spawn ReachCollect(claimed={}, found=[]);
    print(w.found);
    root spawn ReachCollect(claimed={}, found=[]);
    print("sof mtl resume demo ready");
}

test "diamond revisit keeps closure complete adversarial" {
    dsp: Codec = make_codec("dsp", "dsp", False);
    ana: Codec = make_codec("analog", "analog", True);
    hdmi: Codec = make_codec("hdmi", "hdmi", False);
    common: Codec = make_codec("mix", "analog", False);
    root ++> dsp;
    # adversarial insertion: hdmi edge first forces revisit of common before deeper path
    link_codecs(dsp, hdmi);
    link_codecs(dsp, ana);
    link_codecs(hdmi, common);
    link_codecs(ana, common);
    reachable: list[str] = get_reachable(dsp);
    assert(sorted(reachable) == sorted(["dsp", "analog", "hdmi", "mix"]));
    order: list[str] = get_resume_order(dsp);
    assert(sorted(order) == sorted(["dsp", "analog", "hdmi", "mix"]));
    assert(len(order) == 4);
    assert(will_wedge_on_resume(dsp) == True);
}

test "wedge only when hdmi present and analog active" {
    dsp1: Codec = make_codec("dsp1", "dsp", False);
    ana1: Codec = make_codec("a1", "analog", True);
    root ++> dsp1;
    link_codecs(dsp1, ana1);
    assert(will_wedge_on_resume(dsp1) == False);
    dsp2: Codec = make_codec("dsp2", "dsp", False);
    hdmi2: Codec = make_codec("h2", "hdmi", False);
    root ++> dsp2;
    link_codecs(dsp2, hdmi2);
    assert(will_wedge_on_resume(dsp2) == False);
    dsp3: Codec = make_codec("dsp3", "dsp", False);
    ana3: Codec = make_codec("a3", "analog", False);
    hdmi3: Codec = make_codec("h3", "hdmi", False);
    root ++> dsp3;
    link_codecs(dsp3, ana3);
    link_codecs(dsp3, hdmi3);
    assert(will_wedge_on_resume(dsp3) == False);
    dsp4: Codec = make_codec("dsp4", "dsp", False);
    ana4: Codec = make_codec("a4", "analog", True);
    hdmi4: Codec = make_codec("h4", "hdmi", False);
    root ++> dsp4;
    link_codecs(dsp4, ana4);
    link_codecs(dsp4, hdmi4);
    assert(will_wedge_on_resume(dsp4) == True);
}

test "unknown id tolerance and hdmi path reach" {
    dsp: Codec = make_codec("dsp", "dsp", False);
    ana: Codec = make_codec("analog", "analog", True);
    root ++> dsp;
    link_codecs(dsp, ana);
    assert(is_reachable(dsp, "hdmi") == False);
    assert(is_reachable(dsp, "no-such-codec") == False);
    assert(is_reachable(dsp, "analog") == True);
    assert(get_reachable(dsp) == ["dsp", "analog"] or sorted(get_reachable(dsp)) == sorted(["dsp", "analog"]));
}

test "cycle skip does not truncate closure" {
    n0: Codec = make_codec("n0", "dsp", False);
    n1: Codec = make_codec("n1", "analog", True);
    n2: Codec = make_codec("n2", "hdmi", False);
    root ++> n0;
    link_codecs(n0, n1);
    link_codecs(n1, n2);
    link_codecs(n2, n0);
    reachable: list[str] = get_reachable(n0);
    assert(sorted(reachable) == sorted(["n0", "n1", "n2"]));
    assert(will_wedge_on_resume(n0) == True);
    assert(is_reachable(n0, "n2") == True);
    assert(len(get_resume_order(n0)) == 3);
}
